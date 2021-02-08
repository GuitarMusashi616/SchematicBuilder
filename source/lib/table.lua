local table = table

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

function table.equal(t,u)
  assert(type(t) == "table" and type(u) == "table", "table expected, got "..type(t).." and "..type(u))
  if table.len(t) ~= table.len(u) then
    return false
  end
  for k,_ in pairs(t) do
    if type(t[k]) == "table" and type(u[k]) == "table" then
      if not table.equal(t[k], u[k]) then
        return false
      end
    else
      if t[k] ~= u[k] then
        return false
      end
    end
  end
  return true
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

function table.print( tbl )
  print(table.tostring(tbl))
end

return table