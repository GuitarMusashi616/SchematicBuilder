require("utils/tools")
require("utils/class")
require("gps")
require("blueprint")
require("blueprintClassic")
require("ZigZagIterator")
require("NBTparser")
require("inventory")

local legacy_dict = require("utils/legacy_string_dictionary")
local r = require("robot")
local component = require("component")
local inv = component.inventory_controller

NBTbuilder = class()

function NBTbuilder:_init(filename)
  self.blueprint = Blueprint.from_filename(filename)
  self.iter = ZigZagIterator(self.blueprint.height, self.blueprint.length, self.blueprint.width)
  self.gps = GPS(-1,-1,-1)
  self.inventory = Inventory()
  self.legacy_ingredients = self.blueprint:legacy_unique_ingredients()
  self.whitelist = {}
  self.whitelist_initialized = false
  --save_table_as_tabulated_file(self.blueprint:unique_ingredients(true), "ingredients")
  --self.state = Refill(self)
end

function NBTbuilder:next(whitelistMode)
  --updates iter to the next non minecraft:air block
  local in_whitelist
  while not in_whitelist do
    if not self.iter:next() then
      return false
    end
    if whitelistMode then
      local block = self.blueprint:legacy_block_name(self.iter.x, self.iter.y, self.iter.z)
      in_whitelist = self.whitelist[block]
    else
      in_whitelist = self.blueprint:block_name(self.iter.x, self.iter.y, self.iter.z) ~= "minecraft:air"
    end
  end
  return true
end

function NBTbuilder:iterator(copyIter)
  local iter = self.iter
  if copyIter then
    iter = self.iter:clone()
  end
  local function skip_not_whitelisted()
    for x,y,z in iter() do
      if self:block_whitelisted(x,y,z) then
        coroutine.yield(x,y,z)
      end
    end
  end
  local co = coroutine.create(skip_not_whitelisted)
  return function()
    if coroutine.status(co) ~= "dead" then
      local status, x, y, z = coroutine.resume(co)
      return x,y,z
    end
  end
end

function NBTbuilder:block_whitelisted(x,y,z)
  assert(self.whitelist_initialized, "whitelist hasn't been initialized yet")
  local block = self.blueprint:legacy_block_name(x,y,z)
  return self.whitelist[block]
end

function NBTbuilder:get_dest()
  return self.iter.x, self.iter.y, self.iter.z
end

function NBTbuilder:go(x,y,z)
  self.gps:go(x,y,z)
end

function NBTbuilder:returning(x,y,z)
  self.gps:returning(x,y,z)
end

function NBTbuilder:orient(compass_heading_order, target_heading)
  --assume block starts at compass_heading_order
  assert(self.inventory.is_holding_wrench == true, "wrench required")
  for i,v in ipairs(compass_heading_order) do
    if compass_heading_order[i] == target_heading then
      break
    end
    r.useDown()
  end
end

function NBTbuilder:placeDown(block_name)
  --self.gps.x, self.gps.y, self.gps.z but also self.iter.x, self.iter.x, self.iter.z
  --just does r.placeDown() if the block has no metadata ie not stairs or slabs or builder has no wrench
  --otherwise it orients the block
  local metadata = self.blueprint:block_metadata(self.iter.x, self.iter.y, self.iter.z)
  local does_require_orientation = self.inventory.is_holding_wrench and metadata
  
  local is_stairs, is_fence_gate, is_slab, is_log, is_hay
  if does_require_orientation then
    if metadata["facing"] and metadata["half"] then
      is_stairs = true
    elseif metadata["facing"] then
      is_fence_gate = true
    elseif metadata["type"] then
      is_slab = true
    elseif metadata["axis"] then
      if block_name:match("log") then
        is_log = true
      else
        is_hay = true
      end
    end
  end
  local block_underneath
  if is_stairs or is_slab then
    r.down()
    block_underneath = r.detectDown()
    r.up()
  end
  
  r.placeDown()
  
  if does_require_orientation then
    --orient compass_heading_order target_heading
    if is_stairs then
      if block_underneath then
        self:orient({"north_bottom","south_bottom","west_top","east_top", "north_top","south_top","west_bottom","east_bottom"}, metadata["facing"].."_"..metadata["half"])
      else
        self:orient({"north_top","south_top","west_bottom","east_bottom","north_bottom", "south_bottom","west_top","east_top"}, metadata["facing"].."_"..metadata["half"])
      end
    elseif is_slab then
      if metadata["type"] == "double" then
        metadata["type"] = "bottom"
      end
      if block_underneath then
        self:orient({"bottom", "top"}, metadata["type"])
      else
        self:orient({"top", "bottom"}, metadata["type"])
      end
    elseif is_log then
      self:orient({"y", "z", "none", "x"}, metadata["axis"])
    elseif is_hay then
      self:orient({"y", "z", "x"}, metadata["axis"])
    elseif is_fence_gate then
      self:orient({"north", "south", "west", "east" }, metadata["facing"])
    end
  end
end

function NBTbuilder:add_to_whitelist(item_table)
  -- make a list of all matching items in inventory from blueprint
  self.whitelist_initialized = true
  for k,v in pairs(item_table) do
    if v.name and v.name ~= "minecraft:air" and not self.whitelist[v.name] and self.legacy_ingredients[v.name] then
      self.whitelist[v.name] = true
    end
  end
end

function NBTbuilder:take_action()
  return self.state:take_action()
end

function NBTbuilder:change_state(state)
  self.state = state(self)
end

BState = class()

function BState:_init(builder)
  self.builder = builder
end

Build = class(BState)

function Build:take_action()
  local x,y,z = self.builder:get_dest()
  self.builder:go(x,y,z)
  local block = self.builder.blueprint:legacy_block_name(x,y,z)
  local hasBlock, slot = self.builder.inventory:find(block)
  if hasBlock then
    r.select(slot)
    self.builder:placeDown(block)
  else
    self.builder:returning(-1,-1,-1)
    self.builder:change_state(Refill)
    return true
  end
  if not self.builder:next(true) then
    self.builder:returning(-1,-1,-1)
    return false
  end
  return true
end

Refill = class(BState)

function Refill:_init(state)
  BState._init(self, state)
  
  self.iter = self.builder.iter:clone()
  self.virtual_inv = VirtualInv(16)
  
  self.builder.inventory:dump_in_chest(0)
  self.chest = self.builder.inventory:scan_chest(0)
  self.builder:add_to_whitelist(self.chest)
end

function Refill:take_action()
  local x,y,z = self.iter:get_xyz()
  local block = self.builder.blueprint:legacy_block_name(x,y,z)
  
  local more_blocks = self.iter:next()
  local inv_room = true
  
  if self.builder.whitelist[block] then
    --todo: slabs type=double require 2x as many blocks
    inv_room = self.virtual_inv:insert(block,1)
  end
  
  if more_blocks and inv_room then
    return true
  else
    self.builder.inventory:grab_goodies(0, self.chest, self.virtual_inv)
    self.builder:change_state(Build)
    return true
  end
end

function NBTbuilder:start()
  -- make sure if the type of item is included in the chest then all items of that type for the build are included
  local continue = true
  while continue do
    continue = self:take_action()
  end
end

function NBTbuilder:refill()
  self:returning(-1,-1,-1)
  self.inventory:dump_in_chest(0)
  local chest = self.inventory:scan_chest(0)
  self:add_to_whitelist(chest)
  
  local vinv = VirtualInv(16)
  for x,y,z in self:iterator(true) do
    local block = self.blueprint:legacy_block_name(x,y,z)
    if not vinv:insert(block,1) then
      break
    end
  end
  self.inventory:grab_goodies(0, chest, vinv)
end

function NBTbuilder:build()
  self:refill()
  for x,y,z in self:iterator() do
    local block = self.blueprint:legacy_block_name(x,y,z)
    local hasBlock, slot = self.inventory:find(block)
    if not hasBlock then
      self:refill()
    end
    self:go(x,y,z)
    --print("placeDown " .. block)
    r.select(slot)
    self:placeDown(block)
  end
  self:returning(-1,-1,-1)
end

--[[local function chest() do
  local chest = inv.getAllStacks(0).getAll()
  
end

function NBTbuilder:simple_refill()
  local sx,sy,sz = self.iter.x, self.iter.y, self.iter.z
  self:go(-1,-1,-1)
  for x,y,z in self.iter() do
    self.blueprint:legacy_block_name(x,y,z)
    
  end
  self.iter:reset(sx,sy,sz)
  self:go(sx,sy,sz)
end

function NBTbuilder:simple_build()
  for x,y,z in self.iter() do
    
  end
end]]

local function fill_virtual_chest(filename)
  local blue = Blueprint.from_filename(filename)
  local tIngr = blue:create_virtual_supply_chest()
  local f = io.open("utils/virtual_chest.lua", "w")
  f:write("virtual_chest = " .. table.tostring(tIngr))
  f:close()
end

local function main(filename)
  --fill_virtual_chest(filename)
  local builder = NBTbuilder(filename)
  builder:build()
end

local tArgs = {...}

if #tArgs == 1 then
  main(tArgs[1])
elseif #tArgs == 2 and tArgs[1] == "-inv" then
  local builder = NBTbuilder(tArgs[2])
  local ing = builder.blueprint:unique_ingredients()
  save_table_as_tabulated_file(ing, "supplies")
  os.execute("less supplies")
elseif #tArgs == 2 and tArgs[1] == "-db" then
  local builder = NBTbuilder(tArgs[2])
  local commands = builder.blueprint:create_give_commands()
  for i,c in pairs(commands) do
    component.debug.runCommand(c)
    os.sleep(0.2)
  end
else
  print("Usage: NBTbuilder <filename>\t - builds schematic")
  print("       NBTbuilder -inv <filename>\t - lists supplies needed")
  print("       NBTbuilder -db <filename>\t - /gives supplies needed")
end


