local r = require("robot")
require("class")

GPS = class()

function GPS:_init(x,y,z,facing)
  self.x = x or 0
  self.y = y or 0
  self.z = z or 0
  self.facing = "east"
end

function GPS:_forward(dir)
  -- dir can be +1 or -1
  if self.facing == "east" then
    self.x = self.x + dir
  elseif self.facing == "west" then
    self.x = self.x - dir
  elseif self.facing =="south" then
    self.z = self.z + dir
  elseif self.facing == "north" then
    self.z = self.z - dir
  end
end

function GPS:forward()
  self:_forward(1)
  r.forward()
end

function GPS:back()
  self:_forward(-1)
  r.back()
end

function GPS:_upward(dir)
  -- dir can be +1 or -1
  dir = dir or 1
  self.y = self.y + dir
end

function GPS:up()
  self:_upward(1)
  r.up()
end

function GPS:down()
  self:_upward(-1)
  r.down()
end

function GPS:turnRight()
  if self.facing == "east" then
    self.facing = "south"
  elseif self.facing == "west" then
    self.facing = "north"
  elseif self.facing =="south" then
    self.facing = "west"
  elseif self.facing == "north" then
    self.facing = "east"
  end
  r.turnRight()
end

function GPS:turnLeft()
  if self.facing == "east" then
    self.facing = "north"
  elseif self.facing == "west" then
    self.facing = "south"
  elseif self.facing =="south" then
    self.facing = "east"
  elseif self.facing == "north" then
    self.facing = "west"
  end
  r.turnLeft()
end

function GPS:go_y(ylvl)
  while self.y < ylvl do
    self:up()
  end
  while ylvl < self.y do
    self:down()
  end
end

function GPS:go_z(zlvl)
  if self.z == zlvl then
    return
  end
  while self.facing ~= "south" do
    self:turnRight()
  end
  while self.z < zlvl do
    self:forward()
  end
  while zlvl < self.z do 
    self:back()
  end
end

function GPS:go_x(xlvl)
  if self.x == xlvl then
    return
  end
  while self.facing ~= "east" do
    self:turnRight()
  end
  while self.x < xlvl do
    self:forward()
  end
  while xlvl < self.x do 
    self:back()
  end
end

function GPS:turn(dir)
  --WIP
  local compass = {north=0,east=1,south=2,west=3}
  local start = compass[self.facing]
  local stop = compass[dir]
  
  local rights = (stop-start)%4 
  local lefts = (4-rights)%4
  
  if rights < lefts then
    for i=1,rights do
      GPS:turnRight()
    end
  else
    for i=1,lefts do 
      GPS:turnLeft()
    end
  end
  --print(rights)
  --print(lefts)
  print()
end

local function test_shortest_turn()
  --WIP
  gps = GPS()
  gps.facing = "north"
  gps:turn("west")
  --should print left turn
  gps.facing = "north"
  gps:turn("east")
  --should print right turn
  gps:turn("south")
  gps:turn("east")
  gps:turn("west")
  gps:turn("north")
end

function GPS:go(x,y,z)
  self:go_y(y)
  self:go_z(z)
  self:go_x(x)
end

function GPS:returning(x,y,z)
  self:go_x(x)
  self:go_z(z)
  self:go_y(y)
end

local function test_GPS()
  gps = GPS()
  gps:forward()
  gps:turnRight()
  gps:forward()
  gps:up()
  gps:go_y(4)
  gps:go_z(2)
  gps:go_x(7)
  gps:go(0,0,0)
end
