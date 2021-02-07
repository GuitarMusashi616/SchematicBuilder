--build checklist
--crescent hammer
--angel upgrade + inv_controller upgrade + hover upgrade
--facing east


local filesystem = require("filesystem")
local files = {
  "GPS",
  "Blueprint",
  "BlueprintNew",
  "BlueprintClassic",
  "Machine",
  "NBTparser",
  "NBTbuilder",
  "ZigZagIterator",
  "VirtualInv",
  "lib/oop",
  "lib/tools",
  "lib/table",
  "data/new_id_to_label",
  "data/classic_id_data_dictionary",
  "utils/download",
}

local repository = "https://raw.githubusercontent.com/GuitarMusashi616/SchematicBuilder/main/"
local tArgs = {...}

if not filesystem.exists("/build") then
  os.execute("mkdir /build")
  os.execute("mkdir /build/utils")
  os.execute("mkdir /build/lib")
  os.execute("mkdir /build/data")
  for _,file in ipairs(files) do
    os.execute("wget " .. repository .."source/".. file..".lua " .. "/build/" .. file ..".lua")
  end
else
  if #tArgs == 0 then
    print("Usage: download <schematic>")
    print("       download -r")
  elseif #tArgs == 1 then
    if tArgs[1] == "-r" then
      os.execute("rm /build/utils/*")
      os.execute("rmdir /build/utils")
      os.execute("rm /build/lib/*")
      os.execute("rmdir /build/lib")
      os.execute("rm /build/data/*")
      os.execute("rmdir /build/data")
      os.execute("rm /build/*")
      os.execute("rmdir /build")
    else
      os.execute("wget " .. repository .. "schematics/" .. tArgs[1] .. " /build/" .. tArgs[1])
    end
  end
end
