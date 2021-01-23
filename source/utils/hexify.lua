--convert byte file to hexadecimal file
local tArgs = {...}

local function to_hex(char)
  local alphahex = {[0]=0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f'}
  local byte = char:byte()
  assert(0 <= byte and byte <= 255)
  local a,b = math.floor(byte/16),byte%16
  return alphahex[a], alphahex[b]
end

function hexify(str, spacing)
  local hex_str = ""
  spacing = spacing or 0
  for i=1,#str do
    local a,b = to_hex(str:sub(i,i))
    hex_str = hex_str .. a .. b .. string.rep(" ",spacing)
  end
  return hex_str
end

local function hex_to_char(hex_byte)
  assert(type(hex_byte) == "string" and #hex_byte == 2, "hex_byte must be a string of length 2")
  local a,b = hex_byte:sub(1,1), hex_byte:sub(2,2)
  local alphahex = {['0']=0,['1']=1,['2']=2,['3']=3,['4']=4,['5']=5,['6']=6,['7']=7,['8']=8,['9']=9,a=10,b=11,c=12,d=13,e=14,f=15}
  local byte = alphahex[a]*16+alphahex[b]
  return string.char(byte)
end

function unhexify(hex_str, spacing)
  local str = ""
  spacing = spacing or 0
  for i=1,#hex_str,2+spacing do
    str = str..hex_to_char(hex_str:sub(i,i+1))
  end
  return str
end

local function test_hexify(file, dest)
  local f = assert(io.open(file, "rb"), "file not found")
  local content = f:read("*a")
  f:close()
  local hex_str = hexify(content)
  
  local f2 = io.open(dest,"wb")
  f2:write(hex_str)
  f2:close()
end

local function test_unhexify(file, dest)
  local f = assert(io.open(file, "rb"), "file not found")
  local content = f:read("*a")
  f:close()
  local str = unhexify(content)

  local f2 = io.open(dest,"wb")
  f2:write(str)
  f2:close()
end

if #tArgs == 2 then
  test_hexify(tArgs[1], tArgs[2])
elseif #tArgs == 3 and tArgs[1] == "-u" then
  test_unhexify(tArgs[2], tArgs[3])
else
  print("Usage: hexify <filename> <destination>")
  print("       hexify -u <filename> <destination>")
end