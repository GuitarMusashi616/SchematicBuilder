--io.write("Usage: ", os.getenv("_"):match("/([^/]+)%.lua$"), " <filename>\n")
local keys = require("keyboard").keys
local term = require("term")
local width, height = term.getViewport()
local tArgs = {...}

if #tArgs == 0 then
  print("Usage: test <filename>")
end

function goforward(buffer, lines)
  buffer.index = buffer.index + lines
  render(buffer)
end

function goback(buffer, lines)
  buffer.index = buffer.index - lines
  render(buffer)
end

function render(buffer)
  term.clear()
  for i,v in ipairs(buffer) do
    if i >= buffer.index and i <= buffer.index+height-2 then
      print(v)
    end
  end
end

--local keys = {q=1,enter=2,down=3,up=4}
local function main()
  local f = io.open(tArgs[1],"r")
  local buffer = {}
  buffer.index = 1

  for l in f:lines() do
    buffer[#buffer+1]=l
  end
  
  render(buffer)

  while true do
    local e, _, _, code = term.pull()
    if e == "interrupted" then
      break
    elseif e == "key_down" then
      if code == keys.q then
        term.clear()
        os.exit() -- abort
      elseif code == keys.enter or code == keys.down then
        goforward(buffer, 1)
      elseif code == keys.up then
        goback(buffer, 1)
      end
    end
  end
end
main()