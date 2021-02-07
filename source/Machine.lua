local oop = require "lib/oop"
local singleton = oop.singleton
local component = require "component"
local inv = component.inventory_controller
local r = require "robot"

local VirtualInv = require "VirtualInv"

local Machine = singleton() -- this one is for robot but might make a parent factory class that returns a class for turtle 

--[[function Machine:_init()
  self.is_holding_wrench = false
end]]

local function cycle(start, max)
  -- 5,16 -> 5,6,7,8,9,10,11,12,13,14,15,16,1,2,3,4
  return coroutine.wrap(
    function()
      for i = start, max do
        coroutine.yield(i)
      end
      
      for i = 1, start-1 do
        coroutine.yield(i)
      end
    end
  )
end

function Machine:dump()
  for i in cycle(r.select(), 16) do
    r.dropDown()
  end
end

function Machine:grab_stuff(vinv)
  -- look at all nearby inventories
  -- grab each stack from vinv
  -- wait for a button press if it can't find the current stack
  assert(#vinv.buckets <= 16, "vinv cannot have more slots than robot inventory")
  
  self:dump()
  local chest = inv.getAllStacks(0):getAll()
  for slot, bucket in ipairs(vinv.buckets) do
    for i, contents in ipairs(chest) do
      -- USES LABEL IMPORTANT
      if bucket.item == contents.label and bucket.count > 0 then
        local amount_received = inv.suckFromSlot(0, i, bucket.count)
        
        if amount_received then
          bucket.count = bucket.count - amount_received
          if bucket.count == 0 then
            bucket.item = "Air"
          end
        end
      end
    end
    if bucket.count > 0 then
      self:press_any_key_to_continue("Add " .. tostring(bucket.count) .. " " ..tostring(bucket.item) .. " to robot inventory")
    end
  end
end

function Machine:press_any_key_to_continue(message)
  print(message)
  print("Press any key to continue")
  while true do
    if coroutine.yield() == "key_down" then
      return
    end
  end
end

function Machine:select(label)
  for i in cycle(r.select(), 16) do
    local item = inv.getStackInInternalSlot(i)
    if item and item.label == label then
      return r.select(i)
    end
  end
end

function Machine:block_underneath()
  local block_underneath
  if upside_down_wrench_clicks then
    r.down()
    block_underneath = r.detectDown()
    r.up()
  end
  return block_underneath
end

function Machine:placeDown(label, wrench_clicks, upside_down_wrench_clicks)
  wrench_clicks = wrench_clicks or 0
  
  if upside_down_wrench_clicks then
    if not self:block_underneath() then
      wrench_clicks = upside_down_wrench_clicks
    end
  end
  -- use only wrench_clicks var now
  
  local is_found = self:select(label)
  if is_found then
    r.placeDown()
    for i =1, wrench_clicks do
      r.useDown()
    end
    return true
  end
end

local function main()
  local m = Machine()
  local vinv = VirtualInv(16)
  vinv:insert("Grass Block",500)
  vinv:insert("Oak Wood Planks",200)
  vinv:insert("Oak Wood Slab",200)
  vinv:insert("Cobblestone",300)
  for i =1,16 do 
    r.select(i)
    r.dropDown()
  end
  m:grab_stuff(vinv)
end

return Machine