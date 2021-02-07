local NBTparser = require "NBTparser"
local BlueprintNew = require "BlueprintNew"
local VirtualInv = require "VirtualInv"
local ZigZagIterator = require "ZigZagIterator"
local component = require "component"
local db = component.debug

local function main()
  local parser = NBTparser('../schematics/Medieval2')
  local blueprint = BlueprintNew(parser.data.Schematic)


  local vinv = VirtualInv(100)
  for x,y,z in ZigZagIterator(blueprint:get_width_height_length())() do
    local label = blueprint:get_label(x,y,z)
    if label ~= "Air" then
      vinv:insert(label)
    end
  end

  for _, bucket in ipairs(vinv.buckets) do
    print(bucket.item, bucket.count)
    --db.runCommand("/give @a " .. bucket.item .. " " .. tostring(bucket.count))
  end
end

main()
