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

function pt(t, i, j, spacing, limit, isKeyOnly)
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

function pts(t, i, j, spacing, limit, isKeyOnly)
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

function keys(t, i, j, spacing)
  pt(t,i,j,spacing,_,true)
end

function save_table_as_tabulated_file(t, filename)
  local f = io.open(filename, "w")
  f:write(pts(t))
  f:close()
end

function table.len(t)
  local i = 0
  for _,_ in pairs(t) do
    i = i + 1
  end
  return i
end

function table.copy(t)
  --works with nested tables, not with metatables ie classes
  local copy = {}
  for k,v in pairs(t) do
    if type(v) == "table" then
      v = table.copy(v)
    end
    --assert(type(v) ~= "table", "copy table does not work with nested tables")
    copy[k] = v
  end
  return copy
end

function table.val_to_str( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end