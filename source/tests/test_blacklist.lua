local SimInv = require "utils/SimulatedInventory"
local Machine = require "Machine"
local BlueprintNew = require "BlueprintNew"


local test = {}
local fixture = {}


function test.blacklist()
  -- check each slot in chest
  -- compare with blueprint
  SimInv():empty()
  SimInv():insert("Grass Block", 300)
  SimInv():insert("Oak Wood", 128)
  
  local blueprint = BlueprintNew("../schematics/MedivalStable1")
  
  
  local blacklist = Machine:get_blacklist(blueprint)
  -- go though every item type
  -- if there aint enough of that item in chest then add it to blacklist
  
  assert(blacklist["Air"])
  assert(blacklist["Oak Wood Stairs"])
  assert(blacklist["Oak Wood Planks"])
  assert(blacklist["Cobblestone"])
  
end

for k,v in pairs(test) do
  v()
end