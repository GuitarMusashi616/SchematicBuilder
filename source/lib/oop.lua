local oop = {}

local function inherit(cls, ...)
  local bases = {...}
  -- copy base class contents into the new class
  for i, base in ipairs(bases) do
    for k, v in pairs(base) do
      cls[k] = v
    end
  end
  -- you can do an "instance of" check using my_instance.is_a[MyClass]
  cls.__index, cls.is_a = cls, {[cls] = true}
  for i, base in ipairs(bases) do
    for c in pairs(base.is_a) do
      cls.is_a[c] = true
    end
    cls.is_a[base] = true
  end
end

local function default_constructor(c,...)
  local instance = setmetatable({}, c)
  local init = instance._init
  if init then 
    init(instance, ...) 
  end
  return instance
end

local function singleton_constructor(c,...)
  if not c.instance then
    c.instance = setmetatable({}, c)
    local init = c.instance._init
    if init then 
      init(c.instance, ...) 
    end
  end
  return c.instance
end

function oop.class(...)
  local cls = {}
  inherit(cls, ...)
  return setmetatable(cls, {__call = default_constructor})
end

function oop.singleton(...)
  local cls = {}
  inherit(cls, ...)
  return setmetatable(cls, {__call = singleton_constructor})
end

function oop.tab(dt, name)
  if name then
    print(name)
  end
  print(dt)
  for k,v in pairs(dt) do
    print(k, v)
  end
  print("meta"..tostring(getmetatable(dt)))
  print()
end

return oop