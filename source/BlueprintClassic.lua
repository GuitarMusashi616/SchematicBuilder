local oop = require "lib/oop"
local class = oop.class
local classic_id_data_dict = require "data/classic_id_data_dictionary"

local Blueprint = require "Blueprint"

local BlueprintClassic = class(Blueprint)

function BlueprintClassic:_init(NBTschematic)
  Blueprint._init(self, NBTschematic)
  assert(self.schematic.Blocks and self.schematic.Data)
end

function BlueprintClassic:index(x,y,z)
  -- 1,3,5 -> 23
  local index = (y*self.length + z)*self.width+x+1
  assert(1 <= index and index <= #self.schematic.Blocks, string.format("index %d out of range", index))
  return index
end

function BlueprintClassic:get_block_id(x,y,z)
  -- 1,3,5 -> 1
  local index = self:index(x,y,z)
  return self.schematic.Blocks[index]
end

function BlueprintClassic:get_block_data(x,y,z)
  -- 1,3,5 -> 0
  local index = self:index(x,y,z)
  return self.schematic.Data[index]
end

function BlueprintClassic:get_label(x,y,z)
  local index = self:index(x,y,z)
  local id = self.schematic.Blocks[index]
  local data = self.schematic.Data[index] or 0 
  if not classic_id_data_dict[id][data] then
    data = 0 -- https://minecraft.gamepedia.com/Java_Edition_data_values/Pre-flattening#Slabs
  end
  return classic_id_data_dict[id][data].label
end

return BlueprintClassic