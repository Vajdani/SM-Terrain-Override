---@diagnostic disable:duplicate-set-field
sm.log.warning("[TERRAIN OVERRIDE] HOOK IN PROGRESS")

--On consequent world loads, the createOverrideWorld will not declare the global
--sm. table that stores the world creation arguments.
--Thus, we need to load it from storage.
if sm[sm.TERRAINOVERRIDEMODUUID] == nil then
    sm.log.warning("[TERRAIN OVERRIDE] LOAD SAVED TERRAIN DATA")
    local terrainData = sm.storage.load(sm.TERRAINOVERRIDEMODUUID)

    --The code will be ran even on the first world load, so we need to check if we
    --have any data saved.
    if terrainData then
        sm.log.warning("[TERRAIN OVERRIDE] LOADED SAVED TERRAIN DATA:", terrainData)

        --Load the terrain data into the sm. table.
        sm[sm.TERRAINOVERRIDEMODUUID] = terrainData
    else
        sm.log.warning("[TERRAIN OVERRIDE] TERRAIN DATA NOT YET SAVED, SKIP LOAD")
        sm[sm.TERRAINOVERRIDEMODUUID] = {
            terrainType = 1,
        }
    end

    --This function will be used by the OverrideWorld class to import the
    --game's globals into the mod's environment, since they are not shared.
    sm[sm.TERRAINOVERRIDEMODUUID .. "GetGameGlobals"] = function() return _G end
end

--The function responsible for creating OverrideWorld, this will be called in GameHook
--by the new sm.world.createWorld function.
sm[sm.TERRAINOVERRIDEMODUUID .. "_createOverrideWorld"] = function(filename, classname, terrainParams, seed)
    sm.log.warning("[TERRAIN OVERRIDE] CREATE WORLD")

    --Assemble a table with the world creation data
    local terrainData = {
        filename = filename,
        classname = classname,
        terrainParams = terrainParams,
        seed = seed,
        terrainType = 1,
    }

    --Save it to storage, and sychronize it to all clients.
    --The clients don't need to be in the game for it to work.
    --This data will be used on consequent world loads by both the server and clients.
    sm.storage.saveAndSync(sm.TERRAINOVERRIDEMODUUID, terrainData)

    --This function will be used by the OverrideWorld class to import the
    --game's globals into the mod's environment, since they are not shared.
    sm[sm.TERRAINOVERRIDEMODUUID .. "GetGameGlobals"] = function() return _G end

    --Load the terrain data into the sm. table.
    sm[sm.TERRAINOVERRIDEMODUUID] = terrainData

    --Create OverrideWorld using the original sm.world.createWorld function.
    --We pass the path to the mod's OverrideWorld script, but pass on all of the original world creation arguments.
    return sm[sm.TERRAINOVERRIDEMODUUID .. "_oldCreateWorld"]("$CONTENT_" .. sm.TERRAINOVERRIDEMODUUID .. "/Scripts/OverrideWorld.lua", classname, terrainParams, seed)
end


--Search for a game class among the globals.
for k, v in pairs(_G) do
    if type(v) == "table" and v.server_onPlayerJoined then
        --Add our terrain type saving function to the game class.
        function v:server_saveNewTerrainData()
            sm.storage.saveAndSync(sm.TERRAINOVERRIDEMODUUID, sm[sm.TERRAINOVERRIDEMODUUID])
        end
    end
end


--Below is the code that handles when the player adds the mod
--onto a world *after* it has been created.

--Set up the world size. It is 1 tile smaller than maximum, because
--of the world border gate tiles not displaying if there isn't any space
--for them.
local size = 127
local cellMinX = -size
local cellMaxX = size - 1
local cellMinY = -size
local cellMaxY = size - 1

--The terrain values for each terrain type.
local fieldReplacements = {
    {
        terrainScript = ("$CONTENT_%s/Scripts/terrain/%s.lua"):format(sm.TERRAINOVERRIDEMODUUID, "terrain_creative_override"),
        groundMaterialSet = "$GAME_DATA/Terrain/Materials/gnd_standard_materialset.json",
        cellMinX = cellMinX,
        cellMaxX = cellMaxX,
        cellMinY = cellMinY,
        cellMaxY = cellMaxY,
        isStatic = false,
    },
    {
        terrainScript = ("$CONTENT_%s/Scripts/terrain/%s.lua"):format(sm.TERRAINOVERRIDEMODUUID, "terrain_flat_override"),
        groundMaterialSet = "$GAME_DATA/Terrain/Materials/gnd_flat_materialset.json",
        cellMinX = cellMinX,
        cellMaxX = cellMaxX,
        cellMinY = cellMinY,
        cellMaxY = cellMaxY,
        isStatic = false,
    },
    {
        terrainScript = ("$CONTENT_%s/Scripts/terrain/%s.lua"):format(sm.TERRAINOVERRIDEMODUUID, "terrain_snow"),
        groundMaterialSet = "$CONTENT_"..sm.TERRAINOVERRIDEMODUUID.."/terrain/gnd_snow_materialset.json",
        cellMinX = cellMinX,
        cellMaxX = cellMaxX,
        cellMinY = cellMinY,
        cellMaxY = cellMaxY,
        isStatic = false,
    },
}

--Credit to crackx for the code below
--TL;DR: We do some magic so that we can intercept when the game
--is setting up the world class's variables, and instead, we assign our own.
oClass = oClass or class
local function CreateMetaTable(metatable, tbl)
    local cls = oClass(metatable)
    cls.__index = metatable.__index
    local instance = cls()
    if (tbl ~= nil) then
        cls.__newindex = nil
        for k, v in pairs(tbl) do
            instance[k] = v
        end
        cls.__newindex = metatable.__newindex
    end
    return instance, cls
end

function class(super)
    local _meta = {}
    local cls, meta = CreateMetaTable(_meta, oClass(super))
    cls.__index = cls
    function meta.__call(self)
        return CreateMetaTable(self)
    end

    function meta.__newindex(self, k, v)
        local newindex = meta.__newindex
        meta.__newindex = nil

        --Here is where the game is trying to adjust the value of
        --one of the world class parameters.
        --We check if our terranData contains a value for that parameter, and if it does
        --we set the parameter's value to it, thus replacing the game's value.
        local terrainData = fieldReplacements[sm[sm.TERRAINOVERRIDEMODUUID].terrainType]
        if terrainData[k] ~= nil then
            cls[k] = terrainData[k]

            --Some parameters don't get set by the game, so we make sure to set them manually.
            cls["isStatic"] = terrainData.isStatic
            cls["groundMaterialSet"] = terrainData.groundMaterialSet
        else
            cls[k] = v
        end

        meta.__newindex = newindex
    end

    return cls
end