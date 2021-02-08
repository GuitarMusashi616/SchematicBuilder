local oop = require "lib/oop"
local tools = require "lib/tools"
local class = oop.class
local new_id_to_label = require "data/new_id_to_label"

local Blueprint = require "blueprint"
local NBTparser = require "NBTparser"
local ZigZagIterator = require "ZigZagIterator"
local Machine = require "machine"

local BlueprintNew = class(Blueprint)


function BlueprintNew:_init(NBTschematic)
  --takes the NBTparser.data as an argument
  Blueprint._init(self, NBTschematic)
  self.block_data_to_palette_name = self:get_block_data_to_palette_dict(self.schematic.Palette)
end

function BlueprintNew:get_block_data_to_palette_dict(palette)
  -- {["minecraft:grass_block[snowy=false]"] = 13} -> {[13] = "minecraft:grass_block[snowy=false]"}
  assert(palette, "Palette does not exist")
  local block_data_to_palette_name = {}
  for k,v in pairs(palette) do
    block_data_to_palette_name[v] = k
  end
  return block_data_to_palette_name
end

function BlueprintNew:block_data(x,y,z)
  -- the BlockData that Palette refers to, returns int
  -- 3,4,5 -> 13
  local index = (y*self.length + z)*self.width+x+1
  assert(1 <= index and index <= #self.schematic.BlockData, string.format("index %d out of range", index))
  return self.schematic.BlockData[index] 
end

function BlueprintNew:palette_name(block_data)
  -- minecraft id with metadata attached, returns string
  -- 13 -> minecraft:grass_block[snowy=false]
  return self.block_data_to_palette_name[block_data]
end

function BlueprintNew:remove_prefix_from_palette_name(palette_name)
  -- minecraft:dirt -> dirt
  return palette_name:match(":(.*)")
end

function BlueprintNew:remove_suffix_metadata_from_palette_name(palette_name)
  -- minecraft:grass_block[snowy=false] -> minecraft:grass_block
  return palette_name:match("^([^%[]*)")
end

function BlueprintNew:get_label(x,y,z)
  -- 5,4,3 -> Grass Block
  local bd = self:block_data(x,y,z)
  local pn = self:palette_name(bd)
  local no_meta_pn = self:remove_suffix_metadata_from_palette_name(pn)
  local label = new_id_to_label[no_meta_pn]
  assert(label, tostring(pn) .. " does not have label")
  return label
end


function BlueprintNew:get_metadata(x,y,z)
  
  local bd = self:block_data(x,y,z)
  local block = self:palette_name(bd)
  local metadata = {}
  
  local str = block:match("%[(.*)%]")
  if not str then return end
  for var_eq_val in str:gmatch("[^,]+") do
    local var = var_eq_val:match("(.*)=")
    local val = var_eq_val:match("=(.*)")
    metadata[var] = val
  end
  return metadata
end

function BlueprintNew:get_wrench_clicks(x,y,z)
  local metadata = self:get_metadata(x,y,z)
  if not metadata then return end
  
  if metadata["facing"] and metadata["half"] then
    -- is stairs
    local rightside_up = self:orient(
      {"north_bottom","south_bottom","west_top","east_top", "north_top","south_top","west_bottom","east_bottom"}, 
      metadata["facing"].."_"..metadata["half"]
    )
    local upside_down = self:orient(
      {"north_top","south_top","west_bottom","east_bottom","north_bottom", "south_bottom","west_top","east_top"},
      metadata["facing"].."_"..metadata["half"]
    )
    return rightside_up, upside_down
  end
  
  if metadata["facing"] then
    -- is fence gate
    return self:orient({"north", "south", "west", "east" }, metadata["facing"])
  end
  
  if metadata["type"] then
    -- is slab
    if metadata["type"] == "double" then
      metadata["type"] = "bottom"
    end
    local rightside_up = self:orient({"bottom", "top"}, metadata["type"])
    local upside_down = self:orient({"top", "bottom"}, metadata["type"])
    return rightside_up, upside_down
  end
  
  if metadata["axis"] then
    local label = self:get_label(x,y,z)
    if label:match("Wood") then
      -- is log
      return self:orient({"y", "z", "none", "x"}, metadata["axis"])
    else
      -- is hay
      return self:orient({"y", "z", "x"}, metadata["axis"])
    end
  end
end

function BlueprintNew:orient(compass_heading_order, target_heading)
  --{"north", "south", "west", "east" }, "east" -> 3
  local count = 0
  for _,v in ipairs(compass_heading_order) do
    if v == target_heading then
      break
    end
    count = count + 1
  end
  return count
end


local function main()
  local blueprint = BlueprintNew("../schematics/MedivalStable1")
  print(blueprint:get_width_height_length())
  for x,y,z in ZigZagIterator(blueprint:get_width_height_length())() do
    print(x,y,z)
    local label = blueprint:get_label(x,y,z)
    print(label)
    local r,u = blueprint:get_wrench_clicks(x,y,z)
    if r and u then
      print(r,u)
    elseif r then
      print(r)
    end
    
    --Machine():placeDown(label, kwargs) -- kwargs.num_wrench_clicks, kwargs.num_wrench_clicks_upside_down, kwargs.placeDouble
    --machine:placeDown(label, num_wrench_clicks_rightside_up, num_wrench_clicks_upside_down)
  end
end

return BlueprintNew