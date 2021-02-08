local oop = require "lib/oop"
local table = require "lib/table"
local singleton = oop.singleton

local SimulatedInventory = singleton()

function SimulatedInventory:_init()
  self.chest = require "data/virtual_chest"
  self.inv = require "data/virtual_robot_inventory"
end

function SimulatedInventory:default_target(target)
  -- returns self.chest unless "inv" is passed in arg
  if target == "inv" then
    return self.inv
  else
    return self.chest
  end
  
end

function SimulatedInventory:is_empty(target)
  target = self:default_target(target)
  for _,v in ipairs(target) do
    if v and v.label ~= "Air" then
      return false
    end
  end
  return true
end

function SimulatedInventory:empty(target)
  target = self:default_target(target)
  for i,v in ipairs(target) do
    target[i] = {
      label = "Air",
      name = "minecraft:air",
      size = 0,
      maxSize = 64,
    }
  end
end

function SimulatedInventory:overwrite(slot, label, count, target)
  assert(count)
  target = self:default_target(target)
  target[slot] = {label=label, size=count, maxSize=64}
end

function SimulatedInventory:index(i, target)
  target = self:default_target(target)
  return {target[i].label, target[i].size}
end

function SimulatedInventory:tostring(target)
  target = self:default_target(target)
  local str = ""
  for _,v in ipairs(target) do
    str = str .. tostring(v.size) .."\t".. tostring(v.label) .."\n"
  end
  return str
end

function SimulatedInventory:__tostring()
  local str = "Inventory\n"
  for _,v in ipairs(self.inv) do
    str = str .. tostring(v.size) .."\t".. tostring(v.label) .."\n"
  end
  str = str .. "\nChest\n"
  for _,v in ipairs(self.chest) do
    str = str .. tostring(v.size) .."\t".. tostring(v.label) .."\n"
  end
  return str
end

function SimulatedInventory:insert(label, count, target)
  target = self:default_target(target)
  local remaining = count
  local amount_stored = 0
  -- iterate from 1 to chest_size
  for i,v in ipairs(target) do
    
    local is_empty = v.label == "Air" and v.size == 0
    local is_matching = v.label == label
    local is_full = v.size >= 64
    
    -- find first empty / matching stack slot
    if is_empty or (is_matching and not is_full) then
      -- empty up to 64 in that slot
      local up_to_64 = math.min(remaining, 64-v.size)
      
      target[i] = {label=label, size=v.size+up_to_64, maxSize=64}
      -- subtract from remaining 
      remaining = remaining - up_to_64
      amount_stored = amount_stored + up_to_64
      -- continue until all items are inserted
      if remaining <= 0 then
        break 
      end
    end
  end
  if amount_stored == 0 then
    -- if inventory is full (no empty or matching) then return false
    return false
  else
    -- if some items were inserted then return amount_stored
    return amount_stored
  end
end

function SimulatedInventory:remove(label, count, target)
  -- redirect target
  target = self:default_target(target)
  local remaining = count
  local amount_removed = 0
  -- iterate from 1 to chest_size
  for i,v in ipairs(target) do
    -- find first matching stack slot
    local is_matching = v.label == label
    
    if is_matching then
      -- remove up to count
      local up_to_64 = math.min(remaining, v.size)
      local left_in_stack = v.size - up_to_64
      if left_in_stack <= 0 then
        target[i] = {label="Air", name="minecraft:air", size=0, maxSize=64}
      else
        v.size = left_in_stack
      end
      
      -- subtract from remaining 
      remaining = remaining - up_to_64
      amount_removed = amount_removed + up_to_64
      -- continue until count items are removed
      if remaining <= 0 then
        break
      end
    end
  end
    
  -- if not all count items removed them return remaining
  -- if none are removed return false
  if remaining > 0 then
    return amount_removed
  else
    return false
  end
end

return SimulatedInventory
