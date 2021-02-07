-- lets make a simple builder

-- make it so u can split the build easily so multiple robots can work on it

-- make it so that u can either fill the inv of the robot or put a chest under it and put things in its inventory

local oop = require "lib/oop"

local ZigZagIterator = require "ZigZagIterator"
local BlueprintNew = require "BlueprintNew" -- make it so it's automatic whether u get a blueprint or blueprintClassic
local BlueprintClassic = require "BlueprintClassic"
local NBTparser = require "NBTparser"
local Machine = require "Machine"
local GPS = require "GPS"
local VirtualInv = require "VirtualInv"


local function get_blueprint(filename)
  local parser = NBTparser(filename)
  local schematic = parser.data.Schematic
  
  if schematic.Palette and schematic.BlockData then
    return BlueprintNew(parser.data.Schematic)
  elseif schematic.Blocks and schematic.Data then
    return BlueprintClassic(parser.data.Schematic)
  end
end


local function refill(iter_copy, blueprint)
  local vinv = VirtualInv(16)
  
  for x,y,z in iter_copy() do
    local label = blueprint:get_label(x,y,z)
    if label ~= "Air" then
      vinv:insert(label)
    end
  end
  
  Machine():grab_stuff(vinv) -- depends on the robot (could be OpenComputers or ComputerCraft) (holds forever if not there) (try adding to library)
end


local function build(filename)
  local blueprint = get_blueprint(filename)
  local iter = ZigZagIterator(blueprint:get_width_height_length())
  local gps = GPS(-1,-1,0)
  
  for x,y,z in iter() do
    local label = blueprint:get_label(x,y,z)
    local r,u = blueprint:get_wrench_clicks(x,y,z)
    gps:go(x,y,z)
    local success = Machine():placeDown(label, r, u)
    while not success do
      gps:returning(-1,-1,0)
      refill(iter:clone(), blueprint)
      gps:go(x,y,z)
      success = Machine():placeDown(label, r, u)
    end
  end
end


local function main()
  local filenames = {"../Schematics/MedivalStable1", "../Schematics/Modern1", "../Schematics/Medieval2", "../Schematics/medieval-tower"}
  
  for _,filename in ipairs(filenames) do
    build(filename)
    print("DONE\n")
  end
end

build(...)
