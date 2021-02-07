local oop = require "lib/oop"
local class = oop.class

local Bucket = class()

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

local VirtualInv = class()

function VirtualInv:_init(slots)
  assert(slots, "must specify number of slots in virtual inventory")
  self.slots = slots
  self.buckets = {}
  for i=1,slots do
    self.buckets[i] = Bucket()
  end
end

function VirtualInv:insert(item, count)
  assert(item, "must include name of item")
  count = count or 1
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

function VirtualInv:convert_to_openCC_inv()
  local inv = {}
  
  for i,bucket in ipairs(self.buckets) do
    local name = bucket.item
    local size = bucket.count
    local maxSize = bucket.stackLimit
    if name == "empty" then
      name = "minecraft:air"
      size = 0
    end
    inv[i] = {name=name, size=size, maxSize=maxSize}
  end
  
  return inv
end

local function test_virtual_inv()
  vinv = VirtualInv(16)
  print(vinv:insert("minecraft:dirt", 100))
  print(vinv:insert("minecraft:grass", 230))
  print(vinv:insert("minecraft:dirt", 40))
  print(vinv:insert("minecraft:grass",5000))
end

return VirtualInv