require("virtual_chest")
require("virtual_robot_inventory")
selectedSlot = 1
require("tools")

function transferItem(source, sink, count, source_slot, sink_slot)
  
end

local function remove_from_slot(source, slot, count)
  source[slot].size = virtual_chest[slot].size - count
  if source[slot].size <= 0 then
    source[slot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
  end
end

local function find_next_available_slot(source, label)
  --uses selectedSlot
  for i = selectedSlot,#source do
    if source[i].label == label or source[i].size == 0 then
      return i
    end
  end
  
  for i=1,selectedSlot-1 do
    if source[i].label == label or source[i].size == 0 then
      return i
    end
  end
  
  return false
end

local function fill(source, slot, item_reference, remaining)
  --determine whether source[slot] is empty or source[slot] has same item name
  assert(1 <= remaining and remaining <= 64)
  is_empty = source[slot].size == 0
  has_same_label = source[slot].label == item_reference.label
  assert(is_empty or has_same_label, "cannot fill source[slot] with item because it does not have a matching item and is not empty")
  if is_empty then
    --copy the item to source[slot]
    source[slot] = table.copy(item_reference)
    source[slot].size = remaining
    return 0
  end
  
  if has_same_label then
    --add the size amount
    if source[slot].size + remaining > 64 then
      remaining = source[slot].size + remaining - 64
      source[slot].size = 64
      return remaining
    else
      source[slot].size = source[slot].size + remaining
      return 0
    end
  end
end

local function add_to_inventory(source, item_reference, count)
  count = count or 64
  local remaining = math.min(item_reference.size, count)
  local i = find_next_available_slot(source, item_reference.label)
  if not i then
    return false
  end
  remaining = fill(source, i, item_reference, remaining)
  return remaining
  --put item in the next available slot in inventory
  --starting from selectedSlot to 16 to 1 to back to selectedSlot (fill empty slots and matching slots until 0 remaining)
  --if no available slots return false
end

local function test_add_to_inv()
  --print_contents(virtual_chest)
  --print_contents(virtual_robot_inventory)
  --print()
  add_to_inventory(virtual_chest, virtual_robot_inventory[9])
  --print_contents(virtual_chest)
  --print_contents(virtual_robot_inventory)
end

function suckFromSlot(side, slot, count)
  --take everything from that slot and put into inventory
  --print number transferred or false
  count = count or 64
  local amount_to_transfer = math.min(virtual_chest[slot].size, count)
  if amount_to_transfer == 0 then
    return false
  end
  if not add_to_inventory(virtual_robot_inventory, virtual_chest[slot], amount_to_transfer) then
    --can't add the item means inv full
    return false
  end
  remove_from_slot(virtual_chest, slot, amount_to_transfer)
end

function drop(count)
  count = count or 64
  local item_ref = virtual_robot_inventory[selectedSlot]
  local amount_to_transfer = math.min(item_ref.size, count)
  if amount_to_transfer == 0 then
    return false
  end
  --local remaining = amount_to_transfer
  --while remaining and remaining > 0 do
  --  remaining = add_to_inventory(virtual_chest, virtual_robot_inventory[selectedSlot], remaining)
  --end
  
  if not add_to_inventory(virtual_chest, virtual_robot_inventory[selectedSlot], amount_to_transfer) then
    --can't add the item means inv full
    return false
  end
  remove_from_slot(virtual_robot_inventory, selectedSlot, amount_to_transfer)
  --take everything from selectedSlot and put it into chest
  --if one or more of selectedSlot is put into chest them return true
  --drop up to count stackSize
  
end

local function test_suckFromSlot()
  drop(32)
  selectedSlot = 3
  drop()
  drop()
  selectedSlot = 1
  suckFromSlot(3,1)
end

function dropIntoSlot(side, slot, count)
  --take everything from selectedSlot and put into chest slot
  --print true
  
end

--false, "inventory full/invalid slot"


function print_contents(source)
  for i,slot in ipairs(source) do
    print(slot.size, slot.name)
  end
  print()
end

test_suckFromSlot()