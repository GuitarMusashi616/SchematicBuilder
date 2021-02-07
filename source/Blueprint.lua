local oop = require "lib/oop"
local class = oop.class

local Blueprint = class()

function Blueprint:_init(NBTschematic)
  if type(NBTschematic) == "string" then
    --if string is passed in assume it's the filename
    local filename = NBTschematic
    local parser = NBTparser(filename)
    NBTschematic = parser.data.Schematic
  end
  assert(NBTschematic and type(NBTschematic) == "table", "Not a valid Schematic")
  
  self.schematic = NBTschematic
  self.length = assert(NBTschematic.Length, "Schematic does not have Length value")
  self.width = assert(NBTschematic.Width, "Schematic does not have Width value")
  self.height = assert(NBTschematic.Height, "Schematic does not have Height value")
end

function Blueprint:get_label(x,y,z)
  assert(false, "must implement interface method")
end

function Blueprint:get_width_height_length()
  return self.width, self.height, self.length
end

return Blueprint