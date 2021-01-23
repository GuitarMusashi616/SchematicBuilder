local r = {}

r.selectedSlot = 1
require("virtual_chest")
require("virtual_robot_inventory")

function r.up()
  print("up")
end

function r.down()
  print("down")
end

function r.forward()
  print("forward")
end

function r.back()
  print("back")
end

function r.turnRight()
  print("turnRight")
end

function r.turnLeft()
  print("turnLeft")
end

function r.place()
  print(string.format("place %s", virtual_robot_inventory[r.selectedSlot].label))
end

function r.placeDown()
  if virtual_robot_inventory[r.selectedSlot].size > 0 then
    print(string.format("placeDown %s", virtual_robot_inventory[r.selectedSlot].label))
    virtual_robot_inventory[r.selectedSlot].size = virtual_robot_inventory[r.selectedSlot].size - 1
    if virtual_robot_inventory[r.selectedSlot].size <= 0 then
      virtual_robot_inventory[r.selectedSlot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
    end
  else
    print(string.format("cannot placeDown, out of %s", virtual_robot_inventory[r.selectedSlot].label))
  end
end

function r.detect()
  return true
end

function r.detectDown()
  return r.detect()
end

function r.detectUp()
  return r.detect()
end

function r.select(slot)
  r.selectedSlot = slot
end

function r.find_empty_slot(chest)
  for i,v in ipairs(chest) do
    if v.name and v.name == "minecraft:air" then
      return i
    end
  end
end

function r.suck(count)
  --sucks next stack from chest (up to count)
  --returns number sucked
end


function r.drop(count)
  --all of selectedSlot goes into chest 
  --returns true if any of selected slot goes into chest
  local slot = r.find_empty_slot(virtual_chest)
  if slot then
    virtual_chest[slot] = virtual_robot_inventory[r.selectedSlot]
    virtual_robot_inventory[r.selectedSlot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
    return true
  else
    return false
  end
end

function r.dropDown()
  return r.drop()
end

function r.dropUp()
  return r.drop()
end

function r.use()
  print("orientDown")
  return true
end

function r.useUp()
  return r.use()
end

function r.useDown()
  return r.use()
end

return r