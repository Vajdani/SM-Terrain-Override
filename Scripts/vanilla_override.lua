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

        --This function will be used by the OverrideWorld class to import the
        --game's globals into the mod's environment, since they are not shared.
        sm[sm.TERRAINOVERRIDEMODUUID.."GetGameGlobals"] = function() return _G end

        --Load the terrain data into the sm. table.
        sm[sm.TERRAINOVERRIDEMODUUID] = terrainData
    else
        sm.log.warning("[TERRAIN OVERRIDE] TERRAIN DATA NOT YET SAVED, SKIP LOAD")
    end
end

--The function responsible for creating OverrideWorld, this will be called in GameHook
--by the new sm.world.createWorld function.
sm[sm.TERRAINOVERRIDEMODUUID.."_createOverrideWorld"] = function(filename, classname, terrainParams, seed)
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
    sm[sm.TERRAINOVERRIDEMODUUID.."GetGameGlobals"] = function() return _G end

    --Load the terrain data into the sm. table.
    sm[sm.TERRAINOVERRIDEMODUUID] = terrainData

    --Create OverrideWorld using the original sm.world.createWorld function.
    --We pass the path to the mod's OverrideWorld script, but pass on all of the original world creation arguments.
    return sm[sm.TERRAINOVERRIDEMODUUID.."_oldCreateWorld"]("$CONTENT_"..sm.TERRAINOVERRIDEMODUUID.."/Scripts/OverrideWorld.lua", classname, terrainParams, seed)
end

for k, v in pairs(_G) do
    if type(v) == "table" and v.server_onPlayerJoined then
        function v:server_saveNewTerrainData()
            print("jhsfjkhsjkfhk")
            sm.storage.saveAndSync(sm.TERRAINOVERRIDEMODUUID, sm[sm.TERRAINOVERRIDEMODUUID])
            print(sm.storage.load(sm.TERRAINOVERRIDEMODUUID))
        end
    end
end