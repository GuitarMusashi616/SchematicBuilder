local SimInv = require "utils/SimulatedInventory"
local table = require "lib/table"
local VERBOSE = false
local test = {}
local fixture = {}


function fixture.empty()
  SimInv():empty()
  return SimInv()
end

function fixture.messy()
  SimInv():empty()
  for i=1,6 do
    SimInv():overwrite(i, "Grass Block", 64)
  end
  SimInv().chest[6].size = 40
  
  for i=8,15 do
    SimInv():overwrite(i, "Oak Wood Planks", 64)
  end
  
  for i=16,20 do
    SimInv():overwrite(i, "Oak Wood", 64)
  end
  
  for i=22,27 do
    SimInv():overwrite(i, "Cobblestone", 64)
  end
  
  for i=29,34 do
    SimInv():overwrite(i, "Oak Wood Slabs", 64)
  end
  
  for i=37,40 do
    SimInv():overwrite(i, "Cobblestone Stairs", 64)
  end
  
  for i=41,43 do
    SimInv():overwrite(i, "Cobblestone Slabs", 64)
  end
  return SimInv()
end

function test.sim_inv_empty()
  SimInv().chest[1] = {label="Grass Block", size=64, maxSize=64}
  assert(SimInv():is_empty() == false)
  if VERBOSE then
    print(string.format("SimInv is_empty returns %s", SimInv():is_empty()))
    print(table.tostring(SimInv().chest).."\n")
  end
  SimInv():empty()
  if VERBOSE then
    print(string.format("SimInv is_empty returns %s", SimInv():is_empty()))
    print(table.tostring(SimInv().chest).."\n")
  end
  assert(SimInv():is_empty() == true)
end

function test.sim_inv_tostring_target()
  SimInv():empty()
  SimInv().chest[1] = {label="Grass Block", size=58, maxSize=64}
  local contents = SimInv():tostring()
  assert(contents:sub(1,20) == "58\tGrass Block\n0\tAir", "\n"..tostring(contents))
  if VERBOSE then
    print(contents)
  end
end

function test.sim_inv_tostring()
  local sim = fixture.messy()
  print(sim)
end

function test.sim_inv_index()
  local sim = fixture.messy()
  for i=1,5 do
    print(table.tostring(sim:index(i)))
    assert(table.equal(sim:index(i), {"Grass Block", 64}))
  end
  for i=8,15 do
    print(table.tostring(sim:index(i)))
    assert(table.equal(sim:index(i), {"Oak Wood Planks", 64}))
  end
end

function test.sim_inv_insert()
  local sim = fixture.empty()
  sim:insert("Grass Block", 64)
  assert(table.equal(sim:index(1), {"Grass Block", 64}))
  for i=2,5 do
    assert(table.equal(sim:index(i), {"Air", 0}))
  end
  
  local sim2 = fixture.messy()
  assert(sim2:insert("Grass Block", 25) == 25)
  assert(table.equal(sim:index(6), {"Grass Block", 64}))
  assert(table.equal(sim:index(7), {"Grass Block", 1}))
  
  assert(sim2:insert("Grass Block", 500) == 500)
  assert(table.equal(sim:index(7), {"Grass Block", 64}))
  assert(table.equal(sim:index(21), {"Grass Block", 64}))
end

function test.sim_inv_remove()
  local sim = fixture.messy()
  sim:remove("Grass Block", 100)
  assert(table.equal(sim:index(1), {"Air", 0}))
  assert(table.equal(sim:index(2), {"Grass Block", 28}))
end

for k,v in pairs(test) do
  v()
end

local function make_equality_work()
  mt = {__eq = function(lhs, rhs) return (lhs[1] == rhs[1]) and (lhs[2] == rhs[2]) end, __tostring = function(this) return "old meta" end}
  local t = setmetatable({"Grass Block", 20}, mt)
  local f = setmetatable({"Grass Block", 20}, mt)
  print(t == f)
  print(t)
  setmetatable(t, {__eq = function(lhs, rhs) return (lhs[1] == rhs[1]) and (lhs[2] == rhs[2]) end})
  
  print(t == f)
  print(t)
end

--make_equality_work()
--print(5 .. 8)
