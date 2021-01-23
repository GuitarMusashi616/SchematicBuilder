require("utils/class")
require("ZigZagIterator")

local legacy_dict = require("utils/legacy_id_dictionary")
local r = require("robot")
local component = require("component")
local inv = component.inventory_controller


Inventory = class()

function Inventory:_init()
  self.is_holding_wrench = self:is_wrench_equipped()
end

function Inventory:grab_goodies(side, chest, vinv)
  --locate items from vinv (shopping_list) in chest (data) and grab them from side (where real chest is located) 
  for i, bucket in ipairs(vinv.buckets) do
    if bucket.item == "empty" then
      return
    end
    local slot = self:find_next_item_in_chest(bucket.item, chest)
    --assert(slot, string.format("Could not find %d %s", bucket.count, bucket.item))
    if not slot then
      print(string.format("Could not find %d %s", bucket.count, bucket.item))
      os.exit()
    end
    inv.suckFromSlot(side, slot, bucket.count)
    chest[slot].size = chest[slot].size - bucket.count
    if chest[slot].size <= 0 then
      chest[slot] = {maxSize=64,name="minecraft:air",label="Air",maxDamage=0,hasTag=false,damage=0,size=0}
    end
  end
end

function Inventory:is_wrench_equipped()
  inv.equip()
  local item = inv.getStackInInternalSlot()
  inv.equip()
  if item and item.label == "Crescent Hammer" then
    return true
  end
  return false
end


function Inventory:find_next_item_in_chest(name, chest)
  for i,item in ipairs(chest) do
    if item.name and item.name == name then
      return i 
    end
  end
end

function Inventory:dump_in_chest(side)
  assert(side == 3 or side == 1 or side == 0, "chest must be above, below, or in front of robot")
  local drop = r.drop
  if side == 0 then
    drop = r.dropDown
  elseif side == 1 then
    drop = r.dropUp
  end
  for i=1,16 do
    r.select(i)
    drop()
  end
  r.select(1)
end

function Inventory:scan_chest(side)
  return inv.getAllStacks(side):getAll()
end

function Inventory:scan_inv()
  local inventory = {}
  for i=1,16 do
    inventory[i] = inv.getStackInInternalSlot(i)
  end
  return inventory
end

function Inventory:find(block)
  for i = 1,16 do
    local item = inv.getStackInInternalSlot(i)
    if item and item.name == block then
      return true, i
    end
  end
  return false
end

VirtualInv = class()

function VirtualInv:_init(slots)
  self.slots = slots
  self.buckets = {}
  for i=1,slots do
    self.buckets[i] = Bucket()
  end
end

function VirtualInv:insert(item, count)
  assert(item and count, "must include name and count")
  local remaining = count
  -- fill matching buckets
  remaining = self:fill_matching_slots(item, remaining)
  if remaining == 0 then return true, remaining end
  -- fill empty buckets
  remaining = self:fill_new_slots(item, remaining)
  if remaining == 0 then return true, remaining end
  return false, remaining
end


function VirtualInv:fill_matching_slots(item, count)
  local remaining = count
  for i,bucket in ipairs(self.buckets) do
    if bucket:has_item(item) and not bucket:is_full() then
      remaining = remaining - bucket:insert(item,remaining)
      if remaining == 0 then break end
    end
  end
  return remaining
end

function VirtualInv:fill_new_slots(item, count)
  local remaining = count
  for i,bucket in ipairs(self.buckets) do
    if bucket:is_empty() then
      remaining = remaining - bucket:insert(item,remaining)
      if remaining == 0 then break end
    end
  end
  return remaining
end


Bucket = class()

function Bucket:_init()
  self.stackLimit = 64
  self.item = "empty"
  self.count = 0
end

function Bucket:empty()
  self.item = "empty"
  self.count = 0
end

function Bucket:has_item(item)
  if self.item == item then
    return true
  end
  return false
end

function Bucket:insert(item, count)
  assert(self.item == "empty" or self.item == item)
  local space = self.stackLimit-self.count
  local amount_stored = math.min(space,count)
  
  if self.item == "empty" then
    self.item = item
  end
  self.count = self.count + amount_stored
  
  return amount_stored
end

function Bucket:remove(item, count)
  assert(self.item ~= "empty" and self.item == item and self.count >= count)
  self.count = self.count - count
  if self.count == 0 then
    self.item = "empty"
  end
end

function Bucket:is_full()
  assert(self.count <= self.stackLimit, string.format("Bucket has more than %d items, approximately %d",self.stackLimit,self.count))
  if self.count == self.stackLimit then
    return true
  end
  return false
end

function Bucket:is_empty()
  if self.item == "empty" then
    return true
  end
  return false
end

local function test_virtual_inv()
  vinv = VirtualInv(16)
  print(vinv:insert("minecraft:dirt", 100))
  print(vinv:insert("minecraft:grass", 230))
  print(vinv:insert("minecraft:dirt", 40))
  print(vinv:insert("minecraft:grass",5000))
end
