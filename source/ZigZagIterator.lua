--zig zag iterator

local oop = require "lib/oop"
local tools = require "lib/tools"

local class = oop.class

local ZigZagIterator = class()

function ZigZagIterator:_init(xmax, ymax, zmax, x, y, z)
  --width, height, length should match the Schematic.Width, Schematic.Height, Schematic.Length
  --goes from 0,0,0 to height-1, width-1, length-1
  if type(xmax) == "table" and xmax.is_a[ZigZagIterator] and not ymax and not zmax then
    --clone
    zzi = xmax
    self.width = zzi.width
    self.height = zzi.height
    self.length = zzi.length
    
    self.x = zzi.x
    self.y = zzi.y
    self.z = zzi.z
    
    if zzi.state.is_a[addZaddX] then
      self.state = addZaddX(self)
    elseif zzi.state.is_a[subZaddX] then
      self.state = subZaddX(self)
    elseif zzi.state.is_a[addZsubX] then
      self.state = addZsubX(self)
    elseif zzi.state.is_a[subZsubX] then
      self.state = subZsubX(self)
    end
    return
  end
  
  assert(xmax and type(xmax) == "number", "missing args")
  assert(ymax and type(ymax) == "number", "missing args")
  assert(zmax and type(zmax) == "number", "missing args")
  
  self.width = xmax-1
  self.height = ymax-1
  self.length = zmax-1

  self.x = x or 0
  self.y = y or 0
  self.z = z or 0
  
  self.state = addZaddX(self)
end

function ZigZagIterator:clone()
  return ZigZagIterator(self)
end


function ZigZagIterator:__call()
  local first, continue = true, true
  return function()
    if not first then
      continue = self:next()
    end
    if continue then
      first = false
      return self.x,self.y,self.z
    end
  end
end

--[[
function ZigZagIterator:__call()
  if self:next() then
    return self.x, self.y, self.z
  else
    return
  end
end
]]

function ZigZagIterator:next()
  if self.x >= self.width and self.y >= self.height and self.z >= self.length then
    return false
  end
  self.state:next()
  return true
end

function ZigZagIterator:get_xyz()
  return self.x, self.y, self.z
end

function ZigZagIterator:reset(x,y,z)
  self.x = x or 0 
  self.y = y or 0
  self.z = z or 0
end

function ZigZagIterator:change_state(state)
  assert(state.is_a[ZZstate])
  self.state = state(self)
end

ZZstate = class()

function ZZstate:_init(zzi)
  assert(zzi.is_a[ZigZagIterator])
  self.zzi = zzi
end

addZaddX = class(ZZstate)

function addZaddX:next()
  local xmax = self.zzi.x == self.zzi.width
  local zmax = self.zzi.z == self.zzi.length
  
  if zmax and xmax then
    self.zzi.y = self.zzi.y + 1
    self.zzi:change_state(subZsubX)
  elseif xmax then
    self.zzi.z = self.zzi.z + 1
    self.zzi:change_state(addZsubX)
  else
    self.zzi.x = self.zzi.x + 1
  end
end

addZsubX = class(ZZstate)

function addZsubX:next()
  local xzero = self.zzi.x == 0
  local zmax = self.zzi.z == self.zzi.length
  
  if zmax and xzero then
    self.zzi.y = self.zzi.y + 1
    self.zzi:change_state(subZaddX)
  elseif xzero then
    self.zzi.z = self.zzi.z + 1
    self.zzi:change_state(addZaddX)
  else
    self.zzi.x = self.zzi.x - 1
  end
end

subZsubX = class(ZZstate)

function subZsubX:next()
  local xzero = self.zzi.x == 0
  local zzero = self.zzi.z == 0
  
  if zzero and xzero then
    self.zzi.y = self.zzi.y + 1
    self.zzi:change_state(addZaddX)
  elseif xzero then
    self.zzi.z = self.zzi.z - 1
    self.zzi:change_state(subZaddX)
  else
    self.zzi.x = self.zzi.x - 1
  end
end

subZaddX = class(ZZstate)

function subZaddX:next()
  local xmax = self.zzi.x == self.zzi.width
  local zzero = self.zzi.z == 0
  
  if xmax and zzero then
    self.zzi.y = self.zzi.y + 1
    self.zzi:change_state(addZsubX)
  elseif xmax then
    self.zzi.z = self.zzi.z - 1
    self.zzi:change_state(subZsubX)
  else
    self.zzi.x = self.zzi.x + 1
  end
end


local function test_iter()
  zzi = ZigZagIterator(3,5,4)
  for i=1,100 do
    zzi:next()
    pt({x=zzi.x, y=zzi.y, z=zzi.z})
    print()
  end
end

return ZigZagIterator
