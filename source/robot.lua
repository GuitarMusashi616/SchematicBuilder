local r = {}
local SimInv = require "utils/SimulatedInventory"
local table = require "lib/table"

r.selectedSlot = 1

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
  print(string.format("place %s", SimInv().inv[r.selectedSlot].label))
end

function r.select(i)
  if i then
    r.selectedSlot = i
  end
  return r.selectedSlot
end

function r.placeDown()
  if SimInv().inv[r.selectedSlot].size > 0 then
    print(string.format("placeDown %s", SimInv().inv[r.selectedSlot].label))
    SimInv().inv[r.selectedSlot].size = SimInv().inv[r.selectedSlot].size - 1
    if SimInv().inv[r.selectedSlot].size <= 0 then
      SimInv().inv[r.selectedSlot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
    end
  else
    print(string.format("cannot placeDown, out of %s", SimInv().inv[r.selectedSlot].label))
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

function r.find_empty_slot(chest)
  for i,v in ipairs(chest) do
    if v.name and v.name == "minecraft:air" or v.label == "Air" then
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
  local slot = r.find_empty_slot(SimInv().chest)
  if slot then
    SimInv().chest[slot] = table.copy(SimInv().inv[r.selectedSlot])
    SimInv().inv[r.selectedSlot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
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