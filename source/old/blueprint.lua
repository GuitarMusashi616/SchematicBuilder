-- robot places stairs facing towards robot by default
-- robot placeUp or placeDown stairs face north by default
-- stairs rotate clockwise with wrench by default

require("NBTparser")
require("utils/tools")
require("utils/class")


local legacy_dict = require("utils/legacy_string_dictionary")
-- goal: print out the schematic arrangement of blocks
-- from gps(0,0,0) find correct block to place - find Palette ID then match that ID with Block

local Blueprint = class()

function Blueprint:_init(NBTschematic)
  --takes the NBTparser.data as an argument
  if type(NBTschematic) == "string" then
    --if string is passed in assume it's the filename
    local parser = NBTparser(NBTschematic)
    NBTschematic = parser.data.Schematic
  end
  assert(NBTschematic and type(NBTschematic) == "table", "Not a valid Schematic")
  self.schematic = NBTschematic
  self.length = assert(NBTschematic.Length, "Schematic does not have Length value")
  self.width = assert(NBTschematic.Width, "Schematic does not have Width value")
  self.height = assert(NBTschematic.Height, "Schematic does not have Height value")
  self.id_to_data = {}
  if not NBTschematic.Palette and NBTschematic.SchematicaMapping then
    NBTschematic.Palette = NBTschematic.SchematicaMapping
  end
  for k,v in pairs(assert(NBTschematic.Palette, "Palette does not exist")) do
    assert(self.id_to_data[v] == nil, string.format("id_to_data[%d] already exists, has value %s", v, tostring(k)))
    self.id_to_data[v] = k
  end
end

--[[function Blueprint.from_filename(filename)
  local parser = NBTparser(filename)
  local NBTschematic = parser.data.Schematic
  if NBTschematic.Palette and NBTschematic.BlockData then
    return Blueprint(filename)
  elseif NBTschematic.Blocks and NBTschematic.Data then
    require("blueprintClassic")
    return BlueprintClassic(filename)
  end
end]]

function Blueprint:block_id(x,y,z)
  local index = (y*self.length + z)*self.width+x+1
  assert(1 <= index and index <= #self.schematic.BlockData, string.format("index %d out of range", index))
  return self.schematic.BlockData[index]
end

function Blueprint:block_data(block_id)
  assert(block_id and type(block_id) == "number", "block_id must be a number")
  local block_data = self.id_to_data[block_id]
  return block_data
end
  
function Blueprint:block_name(x,y,z,simpleMode)
  --combines block_id and block_data
  local block_id = self:block_id(x,y,z)
  local block_data = self:block_data(block_id)
  if simpleMode then
    block_data = block_data:match("^([^%[]*)")
  end
  return block_data
end

function Blueprint:legacy_block_name(x,y,z)
  local block = self:block_name(x,y,z,true)
  if legacy_dict[block] then
    block = legacy_dict[block]
  end
  return block
end

function Blueprint:block_metadata(x,y,z)
  local block = self:block_name(x,y,z)
  local metadata = {}
  local str = block:match("%[(.*)%]")
  if not str then return end
  for var_eq_val in str:gmatch("[^,]+") do
    local key = var_eq_val:match("(.*)=")
    local val = var_eq_val:match("=(.*)")
    metadata[key] = val
  end
  return metadata
end

function Blueprint:check_if_empty(ylvl)
  for x=1,self.length do
    for z=1,self.width do
      if self:block_id(x,ylvl,z) ~= 0 then
        return false
      end
    end
  end
  return true
end

function Blueprint:ingredients(shorten)
  local ingredients = {}
  for y=0,self.height-1 do
    for x=0,self.width-1 do
      for z=0,self.length-1 do
        local name = self:block_name(x,y,z)
        if shorten then
          name = name:match(":(.*)")
        end
        if not ingredients[name] then
          ingredients[name] = 0
        end
        ingredients[name] = ingredients[name]+1
      end
    end
  end
  return ingredients
end

function Blueprint:unique_ingredients(shorten)
  local unique_ingredients = {}
  for k,v in pairs(self:ingredients(shorten)) do
    assert(type(k) == "string", "key must be a string")
    assert(type(v) == "number", "value must be a number")
    local key = k:match("^([^%[]*)")
    if not unique_ingredients[key] then
      unique_ingredients[key] = 0
    end
    unique_ingredients[key] = unique_ingredients[key] + v
  end
  return unique_ingredients
end

function Blueprint:legacy_unique_ingredients()
  local unique_ingredients = self:unique_ingredients()
  local legacy_ingredients = {}
  for k,v in pairs(unique_ingredients) do
    if legacy_dict[k] then
      legacy_ingredients[legacy_dict[k]] = v
    else
      legacy_ingredients[k] = v
    end
  end
  return legacy_ingredients
end

function Blueprint:save_ingredients(filename, shorten)
  local f = io.open(filename, "w")
  f:write(pts(self:unique_ingredients(shorten)))
  f:close()
end

function Blueprint:load_ingredients(filename)
  --returns a table
  local t = {}
  local f = io.open(filename, "r")
  for l in f:lines() do
    key,val = l:match("([%D]*)(%d*)")
    key = key:match( "(.-)%s*$" )
    t[key] = tonumber(val)
  end
  f:close()
  return t
end

function Blueprint:find_next_occurence(name, iterator)
  local iter_clone = iterator:clone()
  while true do
    if not iter_clone:next() then
      return false
    end
    local block = self:block_name(iter_clone.x,iter_clone.y,iter_clone.z,true)
    if block == name then
      return iter_clone.x, iter_clone.y, iter_clone.z
    end
  end
end

function Blueprint:fill_virtual_inv_with_supplies(extraSlots)
  extraSlots = extraSlots or 0
  local tIngr = self:legacy_unique_ingredients()
  local stacksNeeded = 0
  for k,v in pairs(tIngr) do
    stacksNeeded = stacksNeeded + math.ceil(v/64)
  end
  
  local v_chest = VirtualInv(stacksNeeded+extraSlots)
  for k,v in pairs(tIngr) do
    if k ~= "minecraft:air" then
      v_chest:insert(k,v)
    end
  end
  return v_chest
end

function Blueprint:create_virtual_supply_chest()
  local v_chest = self:fill_virtual_inv_with_supplies(30)
  return v_chest:convert_to_openCC_inv()
end

function Blueprint:create_give_commands()
  local v_chest = self:fill_virtual_inv_with_supplies(30)
  local commands = {}
  for i,bucket in ipairs(v_chest.buckets) do
    if bucket.item ~= "empty" then
      commands[#commands+1] = "/give @p " .. tostring(bucket.item) .. " " .. tostring(bucket.count)
    end
  end
  return commands
end

local function main()
  local parser = NBTparser("Medieval2")
  local blueprint = Blueprint(parser.data.Schematic)
end

local function test_load_ingredients()
  local blueprint = Blueprint("../schematics/medieval-tower")
  save_table_as_tabulated_file(blueprint:unique_ingredients(true), "ingredients")
end

local function test_get_metadata()
  local blueprint = Blueprint("MedivalStable1")
  blueprint:block_metadata(5,5,5)
  blueprint:block_metadata(3,2,3)
  blueprint:block_metadata(7,1,20)
  blueprint:block_metadata(4,1,10)
  require("ZigZagIterator")
  local zzi = ZigZagIterator(blueprint.height,blueprint.length,blueprint.width)
  print(blueprint:find_next_occurence("minecraft:cauldron", zzi))
end

return Blueprint

--test_load_ingredients()
