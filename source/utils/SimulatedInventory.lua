local oop = require "lib/oop"
local singleton = oop.singleton

local SimulatedInventory = singleton()

function SimulatedInventory:_init()
  self.chest = require "data/virtual_chest"
  self.inv = require "data/virtual_robot_inventory"
end

return SimulatedInventory
