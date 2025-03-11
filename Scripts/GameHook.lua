---@diagnostic disable:duplicate-set-field

---@class GameHook : ToolClass
GameHook = class()

function GameHook:server_onCreate()
    if g_terrainOverrideGameHook then return end

    g_terrainOverrideGameHook = self.tool
end

function GameHook:sv_switchTerrain(player)
    self.network:sendToClient(player, "cl_switchTerrain")
end

function GameHook:sv_selectTerrain(type)
    sm[sm.TERRAINOVERRIDEMODUUID].terrainType = type
    sm.event.sendToGame("server_saveNewTerrainData")
end


local terrainTypes = {
    "Standard - 128x128",
    "Flat - 128x128",
    "Standard Snowy - 128x128",
    -- "Standard - Default size"
}

local terrainTypeToIndex = {}
for k, v in pairs(terrainTypes) do
    terrainTypeToIndex[v] = k
end

function GameHook:cl_switchTerrain()
    local gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/switchTerrain.layout", true)
    gui:setText("Name", "Terrain Type")
    gui:setText("SubTitle", "Select which type you'd like")
    gui:createDropDown("items", "cl_selectTerrain", terrainTypes)

    gui:setSelectedDropDownItem("items", terrainTypes[sm[sm.TERRAINOVERRIDEMODUUID].terrainType])

    gui:open()

    self.gui = gui
end

function GameHook:cl_selectTerrain(option)
    local index = terrainTypeToIndex[option]
    if index == sm[sm.TERRAINOVERRIDEMODUUID].terrainType then return end

    self.network:sendToServer("sv_selectTerrain", index)

    self.gui:close()
    sm.gui.chatMessage("Reenter the world for the change to take effect!")
end


sm.log.warning("[TERRAIN OVERRIDE] START")

--This script is responsible for hooking sm. functions to load the mod's vanilla_override script,
--that takes care of creating the OverrideWorld.
--The reason why we have to bounce back and forth between the mod's, and the game's environment, is because of globals.
--Globals are not shared between environments, so if our environment doesn't have the game's variables,
--OverrideWorld will error out and break everything.

--Load the mod's uuid, this will be used later to refer to the mod's files.
--Don't forget to manually change the mod uuid in terrain_creative_override, if you
--intend on using that script. The terrain generation has it's own environment,
--thus it cannot see this variable.
local description = sm.json.open("$CONTENT_DATA/description.json")
sm.TERRAINOVERRIDEMODUUID = description.localId

--Whether the mod's override script has been injected
gameHooked = gameHooked or false

commandsLoaded = commandsLoaded or false

--Imports the override script into the game's environment
local function attemptHook()
    sm.log.warning("[TERRAIN OVERRIDE] TRY HOOK")
    if not gameHooked then --Has the script been loaded yet?
        sm.log.warning("[TERRAIN OVERRIDE] HOOK BEGIN")
        gameHooked = true --Now it has.

        --Load override script
        dofile("$CONTENT_"..sm.TERRAINOVERRIDEMODUUID.."/Scripts/vanilla_override.lua")
    end
end

local function attemptChatBindHook()
    sm.log.warning("[TERRAIN OVERRIDE] TRY CHAT BIND HOOK")
    if not commandsLoaded then
        sm.log.warning("[TERRAIN OVERRIDE] CHAT BIND HOOK BEGIN")
        commandsLoaded = true

        -- if sm.isHost then
        --     sm.game.bindChatCommand("/switchTerrain", {}, "cl_onChatCommand", "Open a menu that lets you adjust the terrain.")
        -- end
    end

    attemptHook()
end

--Hooks sm.game.bindChatCommand so that it loads the override.
--This is used by clients exclusively, as the override is already loaded for the server
--by the time its called for the server.
oldBind = oldBind or sm.game.bindChatCommand
function sm.game.bindChatCommand(command, params, callback, help)
    sm.log.warning("[TERRAIN OVERRIDE] HOOK ATTEMPT FROM BIND COMMAND")
    attemptChatBindHook() --Try to load override

    --Call the original function, so that it's functionality is retained
    return oldBind(command, params, callback, help)
end

--This is the first sm. functions called by CreativeGame, in UnitManager.
--It is used by the server exclusively to load the override.
oldStorageLoad = oldStorageLoad or sm.storage.load
function sm.storage.load(key)
    sm.log.warning("[TERRAIN OVERRIDE] HOOK ATTEMPT FROM STORAGE LOAD")
    attemptHook()

    return oldStorageLoad(key)
end

--Store the old sm.world.createWorld function, the override script will need it.
sm[sm.TERRAINOVERRIDEMODUUID.."_oldCreateWorld"] = sm[sm.TERRAINOVERRIDEMODUUID.."_oldCreateWorld"] or sm.world.createWorld
function sm.world.createWorld(filename, classname, terrainParams, seed)
    sm.log.warning("[TERRAIN OVERRIDE] HOOK ATTEMPT FROM CREATE WORLD")
    attemptHook()

    --Call the override script's createOverrideWorld to create the world
    return sm[sm.TERRAINOVERRIDEMODUUID.."_createOverrideWorld"](filename, classname, terrainParams, seed)
end



oldWorldEvent = oldWorldEvent or sm.event.sendToWorld
function sm.event.sendToWorld(world, callback, args)
    if callback ~= "sv_e_onChatCommand" then
        return oldWorldEvent(world, callback, args)
    end

    local command = args[1]
    if command == "/switchTerrain" then
        sm.event.sendToTool(g_terrainOverrideGameHook, "sv_switchTerrain", args.player)
    end
end