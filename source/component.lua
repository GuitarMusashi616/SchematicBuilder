local component = {}
require("utils/virtual_chest")
require("utils/virtual_robot_inventory")
local r = require("robot")
require("utils/tools")

component.computer = {}
component.robot = {}
component.inventory_controller = {}
component.generator = {}

component.inventory_controller.getAllStacks = function(side)
  return {["count"]=function() return 3 end, ["getAll"]=function() return virtual_chest end, ["reset"]=function() return end}
end


component.inventory_controller.getStackInInternalSlot = function(slot)
  if not slot then
    return {label="Crescent Hammer"}
  end
  return virtual_robot_inventory[slot]
end

component.inventory_controller.suckFromSlot = function(side, slot, count)
  assert(side == 3 or side == 1 or side == 0,"no inv")
  assert(virtual_chest)
  assert(1 <= slot and slot <= #virtual_chest)
  if count == 0 then
    return
  end
  count = count or virtual_chest[slot].size
  print(string.format("sucking %d %s from slot %s", count, virtual_chest[slot].name, slot) )
  --WIP have to make this actually work later

  local inv_slot = r.find_empty_slot(virtual_robot_inventory)
  if inv_slot then
    virtual_robot_inventory[inv_slot] = table.copy(virtual_chest[slot])
    virtual_robot_inventory[inv_slot].size = count
    virtual_chest[slot].size = virtual_chest[slot].size - count
    if virtual_chest[slot].size <= 0 then
      virtual_chest[slot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
    end
    return true
  else
    return false
  end
end

component.inventory_controller.equip = function()
  return true
end
  
return component