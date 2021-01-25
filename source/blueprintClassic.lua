require("utils/class")
require("utils/tools")
require("blueprint")
require("inventory")
local classic_id_data_dict = require("utils/classic_id_data_dictionary")

BlueprintClassic = class()

function BlueprintClassic:_init(NBTschematic)
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
  
  assert(self.schematic.Blocks and self.schematic.Data, "BlueprintClassic requires Blocks and Data table in Schematic")
  
end

function BlueprintClassic:index(x,y,z)
  local index = (y*self.length + z)*self.width+x+1
  assert(1 <= index and index <= #self.schematic.Blocks, string.format("index %d out of range", index))
  return index
end

function BlueprintClassic:block_id(x,y,z)
  local index = self:index(x,y,z)
  return self.schematic.Blocks[index]
end

function BlueprintClassic:block_data(x,y,z)
  local index = self:index(x,y,z)
  return self.schematic.Data[index]
end
  
function BlueprintClassic:block_name(x,y,z,simpleMode)
  --combines block_id and block_data
  --assert(not simpleMode, "block_name(x,y,z,false) does not provide [*] metadata")
  local index = self:index(x,y,z)
  local block_id = self.schematic.Blocks[index]
  local block_data = self.schematic.Data[index] 
  if classic_id_data_dict[block_id] and classic_id_data_dict[block_id][block_data] then
    return classic_id_data_dict[block_id][block_data].name
  elseif classic_id_data_dict[block_id] and classic_id_data_dict[block_id][0] then
    return classic_id_data_dict[block_id][0].name
  else
    print(string.format("could not find classic_id_data for %d %d", block_id, block_data))
  end
end

function BlueprintClassic:legacy_block_name(x,y,z)
  return self:block_name(x,y,z,true)
end

function BlueprintClassic:ingredients(shorten)
  local ingredients = {}
  for x,y,z in self:iterator() do
    local name = self:block_name(x,y,z)
    if shorten then
      name = name:match(":(.*)")
    end
    if not ingredients[name] then
      ingredients[name] = 0
    end
    ingredients[name] = ingredients[name]+1
  end
  return ingredients
end

function BlueprintClassic:unique_ingredients(shorten)
  return self:ingredients(shorten)
end

function BlueprintClassic:legacy_unique_ingredients()
  return self:ingredients()
end

function BlueprintClassic:iterator()
  local function yzx_iter_coroutine(width, height, length)
    for y=0,height-1 do
      for z=0,length-1 do
        for x=0,width-1 do
          coroutine.yield(x,y,z)
        end
      end
    end
  end
  local width, height, length = self.width, self.height, self.length
  local co = coroutine.create(yzx_iter_coroutine)
  return function()
    if coroutine.status(co) ~= "dead" then
      local status, x, y, z = coroutine.resume(co,width,height,length)
      return x,y,z
    end
  end
end

function BlueprintClassic:fill_virtual_inv_with_supplies(extraSlots)
  extraSlots = extraSlots or 0
  local tIngr = self:legacy_unique_ingredients()
  local length = table.len(tIngr)
  local v_chest = VirtualInv(length+extraSlots)
  for k,v in pairs(tIngr) do
    if k ~= "minecraft:air" then
      v_chest:insert(k,v)
    end
  end
  return v_chest
end

function BlueprintClassic:create_virtual_supply_chest()
  local v_chest = self:fill_virtual_inv_with_supplies(20)
  return v_chest:convert_to_openCC_inv()
end

function BlueprintClassic:create_give_commands()
  local v_chest = self:fill_virtual_inv_with_supplies()
  local commands = {}
  for i,bucket in ipairs(v_chest.buckets) do
    if bucket.item ~= empty then
      commands[#commands+1] = "/give @p " .. tostring(bucket.item) .. " " .. tostring(bucket.count)
    end
  end
  return commands
end

local function main()
  local bc = BlueprintClassic("../schematics/medieval-tower")
  local comm = bc:create_give_commands()
  pt(comm)
end
--create(plusOne)

--i1 = bc:ingredients()
--i2 = bc:unique_ingredients()
--i3 = bc:legacy_unique_ingredients()
--print()