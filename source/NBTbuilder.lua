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
local table = require "lib/table"

local function get_blueprint(filename)
  local parser = NBTparser(filename)
  local schematic = parser.data.Schematic
  
  if schematic.Palette and schematic.BlockData then
    return BlueprintNew(parser.data.Schematic)
  elseif schematic.Blocks and schematic.Data then
    return BlueprintClassic(parser.data.Schematic)
  end
end

local function refill(iter_copy, blueprint, blacklist)
  local vinv = VirtualInv(16)
  
  for x,y,z in iter_copy() do
    local label = blueprint:get_label(x,y,z)
    if not blacklist[label] then
      vinv:insert(label)
    end
  end
  Machine():grab_stuff(vinv) -- depends on the robot (could be OpenComputers or ComputerCraft) (holds forever if not there) (try adding to library)
  
end

local function init_sim(blueprint)
  SimInv().chest = {}
  SimInv().inv = {}
  
  local vinv = VirtualInv(120)
  for x,y,z in ZigZagIterator(blueprint:get_width_height_length())() do
    local label = blueprint:get_label(x,y,z)
    if label ~= "Air" then
      vinv:insert(label)
    end
  end
  
  
  for i,bucket in ipairs(vinv.buckets) do
    if bucket.item == "empty" then
      bucket.item = "Air"
    end
    
    SimInv().chest[i] = {label=bucket.item, size=bucket.count, maxSize=64}
  end
  
  for i=1,16 do
    SimInv().inv[i] = {label="Grass Block", size=64, maxSize=64}
  end
end



local function build(filename)
  local blueprint = get_blueprint(filename)
  --init_sim(blueprint)
  local iter = ZigZagIterator(blueprint:get_width_height_length())
  local gps = GPS(-1,-1,0)
  local machine = Machine()
  local blacklist = machine:get_blacklist(blueprint)
  
  for x,y,z in iter() do
    local label = blueprint:get_label(x,y,z)
    local r,u = blueprint:get_wrench_clicks(x,y,z)
    if not blacklist[label] then
      gps:go(x,y,z)
      local success = machine:placeDown(label, r, u)
      
      if not success then
        gps:returning(-1,-1,0)
        refill(iter:clone(), blueprint, blacklist)
        gps:go(x,y,z)
      end
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

local function next_16_stacks(iter, blueprint)
  -- moves iter forward
  local vinv = VirtualInv(16)
  
  local has_space = true
  for x,y,z in iter() do
    local label = blueprint:get_label(x,y,z)
    if label ~= "Air" then
      if not vinv:insert(label) then
        return vinv, false
      end
    end
  end
  
  return vinv, true
end


local function iter_all_refills(blueprint)
  local iter = ZigZagIterator(blueprint:get_width_height_length())
  local continue = true
  return function()
    if not continue then
      return
    end
    local vinv, last_stack = next_16_stacks(iter, blueprint)
    if last_stack then
      continue = false
    end
    return vinv
  end
end

local function check_if_schem_labels_match_in_game_labels()
  for vinv in iter_all_refills(get_blueprint("../schematics/Modern1")) do
    --print(table.tostring(vinv).."\n")
    Machine():grab_stuff(vinv, true)
    for i=1,16 do
      r.select(i)
      r.drop()
    end
  end
end

build(...)
