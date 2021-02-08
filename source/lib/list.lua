local table = require "lib/table"

local mt = {
  __tostring = function(this)
    return table.tostring(this)
  end,
  __eq = function(lhs, rhs)
    if #lhs ~= #rhs then
      return false
    end
    for i=1,#lhs do
      
      
      if lhs[i] ~= rhs[i] then
        
      end
    end
  end,
  __add = function(lhs, rhs)
    local t = setmetatable({},mt)
    for k,v in lhs do
      
    end
    
  end
  
}

local function list(tab)
  assert(type(tab) == "table", "list constructor requires a table")
  return setmetatable(tab, mt)
end

return list