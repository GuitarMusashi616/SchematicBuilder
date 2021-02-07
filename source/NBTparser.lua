local oop = require("lib/oop")
local class = oop.class

NBTparser = class()

function NBTparser:_init(filename)
  local f = io.open(filename, "rb")
  if not f then
    print(string.format("file %s not found", filename))
    os.exit()
  end
  self.index = 1
  self.content = f:read("*a")
  self.data = {}
  self:start()
  f:close()
end

function NBTparser:read_byte()
  local char = self.content:sub(self.index,self.index)
  self.index = self.index + 1
  return char:byte()
end

function NBTparser:read_string(len)
  local str = self.content:sub(self.index,self.index+len-1)
  self.index = self.index + len
  return str
end

function NBTparser:read_tag()
  local tag = self:read_byte()
  assert(tag and 0 <= tag and tag <= 12, "not a valid tag ID")
  if tag == 0 then
    return tag
  end

  local len = uint(self:read_byte(), self:read_byte())
  local str = self:read_string(len)

  return tag, str
end

function NBTparser:process_tag(id)
  assert(id and 0 <= id and id <= 12)
  if id == 0 then
    return
  elseif id == 1 then    
    return int(self:read_byte()) 
  elseif id == 2 then
    return int(self:read_byte(), self:read_byte())
  elseif id == 3 then
    return int(self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte())
  elseif id == 4 then
    return int(self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte())
  elseif id == 5 then
    for i=1,4 do
      self:read_byte()
    end
    return "float"
  elseif id == 6 then
    for i=1,8 do
      self:read_byte()
    end
    return "double"
  elseif id == 7 then
    return self:read_array("byte")
  elseif id == 8 then
    local len = uint(self:read_byte(), self:read_byte())
    return self:read_string(len)
  elseif id == 9 then
    return self:read_list()
  elseif id == 10 then
    return self:read_compound()
  elseif id == 11 then
    return self:read_array("int")
  elseif id == 12 then
    return self:read_array("long")
  end
end

function NBTparser:read_compound()
  local compound = {}
  local id, name, payload
  while self.index <= #self.content do
    id, name = self:read_tag()
    if id == 0 then
      break
    end
    payload = self:process_tag(id)
    compound[name] = payload
  end
  return compound
end

function NBTparser:start()
  self.data = {}
  local id, name, payload
  while self.index <= #self.content do
    id, name = self:read_tag()
    if id == 0 then
      break
    end
    payload = self:process_tag(id)
    self.data[name] = payload
  end
end

function uint(...)
  local tArgs = {...}
  assert(#tArgs > 0)
  local result = 0
  for i=1,#tArgs do
    assert(0 <= tArgs[i] and tArgs[i] <= 255, "byte must be between 0 and 255")
    result = result + tArgs[i]*256^(#tArgs-i)
  end
  return result
end

function test_uint()
  assert(uint(25) == 25, uint(25))
  assert(uint(10,5) == 2565, uint(10,5))
  assert(uint(0,0,10,5) == 2565, uint(0,0,10,5))
end

function int(...)
  local tArgs = {...}
  assert(#tArgs > 0)
  local result = uint(...)
  local limit = 256^#tArgs
  if result >= limit/2 then
    result = result - limit
  end
  return result
end

function test_int()
  assert(int(127) == 127, int(127))
  assert(int(128) == -128, int(128))
  assert(int(255) == -1, int(255))
  assert(int(10,5) == 2565, int(10,5))
  assert(int(255,255) == -1, int(255,255))
end

function NBTparser:read_array(dtype)
  local array = {}
  local size = int(self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte())
  for i=1,size do
    if dtype == "byte" then
      array[i] = self:read_byte()
    elseif dtype == "int" then
      array[i] = int(self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte())
    elseif dtype == "long" then
      array[i] = int(self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte())
    end
  end
  return array
end

function NBTparser:read_list()
  local tagid = self:read_byte()
  local size = int(self:read_byte(), self:read_byte(), self:read_byte(), self:read_byte())
  local list = {}
  for i=1,size do
    list[i] = self:process_tag(tagid)
  end
  return list
end

local function main()
  local parser = NBTparser("../schematics/medieval-tower")
  print()
end

return NBTparser