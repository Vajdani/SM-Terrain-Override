--Get the world creation data that was given to us by sm.world.createWorld.
local terrainData = sm[sm.TERRAINOVERRIDEMODUUID]

--Load the world script that the game was intending to use, we need to retain it's functionality.
dofile(terrainData.filename)

--Get the dofile'd class, and override some of it's parameters to our liking.
local classInstance = _G[terrainData.classname]

--Makes the chunk loading dynamic. We need this on large worlds.
classInstance.isStatic = false

local terrainTypes = {
    {
        script = "terrain_creative_override",
        materials = "$GAME_DATA/Terrain/Materials/gnd_standard_materialset.json"
    },
    {
        script = "terrain_flat_override",
        materials = "$GAME_DATA/Terrain/Materials/gnd_flat_materialset.json"
    },
    {
        script = "terrain_snow",
        materials = "$CONTENT_"..sm.TERRAINOVERRIDEMODUUID.."/terrain/gnd_snow_materialset.json"
    },
}

local terrainType = terrainTypes[terrainData.terrainType]

--Loads the mod's custom terrain generation script.
classInstance.terrainScript = ("$CONTENT_%s/Scripts/terrain/%s.lua"):format(sm.TERRAINOVERRIDEMODUUID, terrainType.script)

classInstance.groundMaterialSet = terrainType.materials

--Increase the world size to 128 by 128 cells.
--The reason why cellMaxX and cellMaxY are one cell less, is because
--0,0 counts as a cell too, so we need to subtract 1 from it.
local size = 64
classInstance.cellMinX = -size
classInstance.cellMaxX = size - 1
classInstance.cellMinY = -size
classInstance.cellMaxY = size - 1

--This function imports the game environment's globals into the mod's environment
local function ImportGlobals()
    for k, v in pairs(sm[sm.TERRAINOVERRIDEMODUUID.."GetGameGlobals"]()) do
        --Is the global prefixed with _g(most likely a manager), or is it a UUID?
        if k:lower():find("g_") or type(v) == "Uuid" then
            _G[k] = v --Import reference to it.
        end
    end
end

--We override the world's server create function to import all of the game's globals
--before anything is done by the world, since it may use globals. This only applies to
--the server though, so we have to do it for the client as well.
oldServerCreate = oldServerCreate or classInstance.server_onCreate
function classInstance:server_onCreate()
    ImportGlobals()

    oldServerCreate(self)
end

--Periodically reimport globals, in case any new ones have been made.
--Sadly, we don't have access to metatables, which would enable us to do it automatically.
-- oldFixedUpdate = oldFixedUpdate or classInstance.server_onFixedUpdate
-- function classInstance.server_onFixedUpdate(self, dt)
--     if sm.game.getServerTick() % 20 == 0 then
--         ImportGlobals()
--     end

--     if oldFixedUpdate then
--         oldFixedUpdate(self, dt)
--     end
-- end



--Override the world's client create to import all of the game's globals on
--the clients too.
oldClientCreate = oldClientCreate or classInstance.client_onCreate
function classInstance:client_onCreate()
    ImportGlobals()

    oldClientCreate(self)
end