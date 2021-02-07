local component = {}
local r = require "robot"
local SimInv = require "utils/SimulatedInventory"

component.computer = {}
component.robot = {}
component.inventory_controller = {}
component.generator = {}

component.inventory_controller.getAllStacks = function(side)
  return {["count"]=function() return 3 end, ["getAll"]=function() return SimInv().chest end, ["reset"]=function() return end}
end


component.inventory_controller.getStackInInternalSlot = function(slot)
  if not slot then
    return {label="Crescent Hammer"}
  end
  return SimInv().inv[slot]
end

component.inventory_controller.suckFromSlot = function(side, slot, count)
  assert(side == 3 or side == 1 or side == 0,"no inv")
  assert(SimInv().chest)
  assert(1 <= slot and slot <= #SimInv().chest)
  if count == 0 then
    return
  end
  count = count or SimInv().chest[slot].size
  
  --WIP have to make this actually work later
  local inv_slot = r.find_empty_slot(SimInv().inv)
  if inv_slot then
    print(string.format("sucking %d %s from slot %s", count, SimInv().chest[slot].name, slot) )
    SimInv().inv[inv_slot] = table.copy(SimInv().chest[slot])
    SimInv().inv[inv_slot].size = count
    SimInv().chest[slot].size = SimInv().chest[slot].size - count
    if SimInv().chest[slot].size <= 0 then
      SimInv().chest[slot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
    end
    return count
  else
    print("Not Enough Inventory Space in Robot")
    return false
  end
end

component.inventory_controller.equip = function()
  return true
end
  
return component