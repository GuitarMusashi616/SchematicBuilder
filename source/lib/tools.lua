local tools = {}

local function longest(t)
  local longest = 0
  for k,v in pairs(t) do
    local length = #tostring(k)
    if length > longest then
      longest = length
    end
  end
  return longest
end

function tools.pt(t, i, j, spacing, limit, isKeyOnly)
  --prints out a tabulated table lines i to j
  spacing = spacing or 3
  i = i or 1
  j = j or 1000
  limit = limit or 40
  local index = 1
  local length = longest(t)
  for k,v in pairs(t) do
    if index >= i and index <= j then
      local key = tostring(k)
      local val = string.sub(tostring(v),1,limit)
      if isKeyOnly then
        print(key)
      else
        print(key..string.rep(" ",length-#key+spacing)..val)
      end
    end
    index = index + 1
  end
  print()
end

function tools.pts(t, i, j, spacing, limit, isKeyOnly)
  --returns string of a tabulated table lines i to j
  str = ""
  spacing = spacing or 3
  i = i or 1
  j = j or 1000
  limit = limit or 40
  local index = 1
  local length = longest(t)
  for k,v in pairs(t) do
    if index >= i and index <= j then
      local key = tostring(k)
      local val = string.sub(tostring(v),1,limit)
      if isKeyOnly then
        str = str..tostring(key).."\n"
      else
        str = str..key..string.rep(" ",length-#key+spacing)..val.."\n"
      end
    end
    index = index + 1
  end
  str = str.."\n"
  return str
end

function tools.keys(t, i, j, spacing)
  pt(t,i,j,spacing,_,true)
end

function tools.save_table_as_tabulated_file(t, filename)
  local f = io.open(filename, "w")
  f:write(pts(t))
  f:close()
end

return tools