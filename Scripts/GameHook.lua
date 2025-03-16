---@diagnostic disable:duplicate-set-field

--Toggles whether the host can adjust the terrain type or not.
--Disabled by default, can't be toggled from in-game.
TERRAINTYPESWITCHENABLED = false

--This class is for handling the terrain switching functionality. 
---@class GameHook : ToolClass
GameHook = class()

function GameHook:server_onCreate()
    --Don't do anything if there is an instance already.
    --Since this is an autotool, an instance is created for each player.
    if g_terrainOverrideGameHook then return end

    g_terrainOverrideGameHook = self.tool

    --Load the mod's description file, and append any new dependencies
    --that might have been loaded during terrain loading.
    local description = sm.json.open("$CONTENT_DATA/description.json")
    concat(description.dependencies, newDependencies)
    sm.json.save(description, "$CONTENT_DATA/\\description.json")

    --Cleanup for terrain loading.
    customTiles = nil
    newDependencies = nil
end

function GameHook:sv_switchTerrain(player)
    --Send gui open event to the player that typed the command.
    self.network:sendToClient(player, "cl_switchTerrain")
end

function GameHook:sv_selectTerrain(type)
    --Set the global terrain type value, and send an event to
    --the game to save it. It has to be saved in the game environment, or else
    --it won't be seen by it.
    sm[sm.TERRAINOVERRIDEMODUUID].terrainType = type
    sm.event.sendToGame("server_saveNewTerrainData")
end



--Titles for all of the terrain types.
local terrainTypes = {
    "Standard - 128x128",
    "Flat - 128x128",
    "Standard Snowy - 128x128",
    -- "Standard - Default size"
}

--Assamble a dictionary of "terrain type title" -> "index of terrain type"
local terrainTypeToIndex = {}
for k, v in pairs(terrainTypes) do
    terrainTypeToIndex[v] = k
end

function GameHook:cl_switchTerrain()
    --Create and open the gui that lets the player select the new terrain mode.
    local gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/switchTerrain.layout", true)
    gui:setText("Name", "Terrain Type")
    gui:setText("SubTitle", "Select which type you'd like")
    gui:createDropDown("items", "cl_selectTerrain", terrainTypes)

    --Set the selected item in the dropdown.
    gui:setSelectedDropDownItem("items", terrainTypes[sm[sm.TERRAINOVERRIDEMODUUID].terrainType])

    gui:open()

    self.gui = gui
end

function GameHook:cl_selectTerrain(option)
    --Get the index of the terrain type from the name.
    local index = terrainTypeToIndex[option]

    --If its the selected type, don't do anything.
    if index == sm[sm.TERRAINOVERRIDEMODUUID].terrainType then return end

    --Send an event to the server to save the change.
    self.network:sendToServer("sv_selectTerrain", index)

    --Close gui, print warning in the chat.
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

--Whether the mods's custom chat commands have been injected
commandsLoaded = commandsLoaded or false

--Whether the custom tile addons have been injected
customTilesLoaded = customTilesLoaded or false

--Import the ModDatabase class that we'll later use for
--detecting custom tile addons.
dofile("$CONTENT_40639a2c-bb9f-4d4f-b88c-41bfe264ffa8/Scripts/ModDatabase.lua")

--Loads the custom tiles' data.
local function loadCustomTiles()
    --Don't do anything if we have loaded the data.
    if customTilesLoaded then return end

    --The tiles are beind loaded.
    --We must set this here, and not later, or else the sm.storage.load() call
    --under this would cause an infinite loop.
    customTilesLoaded = true

    --Initialise the mod database.
    ModDatabase.loadShapesets()

    --Set up the tiles table, load the saved data or default to nothing.
    customTiles = sm.storage.load(sm.TERRAINOVERRIDEMODUUID.."_tileList") or {
        added = {},
        removed = {}
    }

    --Table for any new asset pack dependencies that have been detected.
    newDependencies = {}

    --Tiles can have asset packs for custom terrain assets.
    --The game does not import them on it's own, so we need to do it
    --ourselves. This can be done by adding those asset packs to
    --the mod's dependencies. A world reload will be required for the
    --change to take effect.
    --I have not tested if this works in multiplayer.

    --Assamble a list of already imported dependencies. This will be used
    --to avoid duplicate entries in the mod's dependencies list.
    local presentDependencies = {}
    for k, v in pairs(description.dependencies) do
        presentDependencies[v.localId] = true
    end

    --Function from Survival/Scripts/util.lua, checks if value is in array.
    local function isAnyOf(is, off)
        for _, v in pairs(off) do
            if is == v then
                return true
            end
        end
        return false
    end

    --Function that checks if the new tiles are present yet, if not,
    --it adds them. It also removes them from the opposite tile list if present.
    local function AddTiles(addTo, removeFrom, newTiles)
        for k, path in pairs(newTiles) do
            --Is the new tile in the table we are adding to?
            if not isAnyOf(path, addTo) then
                table.insert(addTo, path) --Insert if so.
            end

            --Find the index of the new tile in the table we are
            --removing from, and remove it by index, if its found.
            for removedTileId, removedTilePath in pairs(removeFrom) do
                if path == removedTilePath then --New tile found in the list.
                    table.remove(removeFrom, removedTileId) --Remove it.
                end
            end
        end
    end

    --Loop over all mods detected by the database.
    for k, uuid in pairs(ModDatabase.getAllLoadedMods()) do
        --The path to the tile list in the addon.
        local tileListPath = ("$CONTENT_%s/tileList.json"):format(uuid)

        --Can't calle fileExists directly, will throw an error.
        --pcall() allows us to get around this.
        local success, result = pcall(sm.json.fileExists, tileListPath)

        --Was the call successful, does the file exist?
        if success and result then
            --Open the file and append it to the customTiles table.
            local data = sm.json.open(tileListPath)

            --Add the tiles to the list.
            AddTiles(customTiles.added, customTiles.removed, data.addedTiles or {})
            AddTiles(customTiles.removed, customTiles.added, data.removedTiles or {})

            --Loop over the addon's dependencies.
            for _k, dependency in pairs(data.dependencies or {}) do
                --Are we missing the asset pack?
                if presentDependencies[dependency.localId] == nil then
                    --Add it to the list.
                    presentDependencies[dependency.localId] = true
                    table.insert(newDependencies, dependency)
                end
            end
        end
    end

    --Clean up the database, we don't need it anymore.
    ModDatabase.unloadShapesets()
end


--Imports the override script into the game's environment
local function attemptHook()
    sm.log.warning("[TERRAIN OVERRIDE] TRY HOOK")
    if not gameHooked then --Has the script been loaded yet?
        sm.log.warning("[TERRAIN OVERRIDE] HOOK BEGIN")
        gameHooked = true --Now it has.

        --Load override script
        dofile("$CONTENT_"..sm.TERRAINOVERRIDEMODUUID.."/Scripts/vanilla_override.lua")
    end

    if sm.isServerMode() then
        sm.log.error("[TERRAIN OVERRIDE] load terrain stuff")

        loadCustomTiles()

        sm.storage.saveAndSync(sm.TERRAINOVERRIDEMODUUID.."_tileList", customTiles)
        --sm.json.save(tiles, "$CONTENT_"..sm.TERRAINOVERRIDEMODUUID.."/customTileList.json")
    end
end

--Loads the mod's custom chat commands
local function attemptChatBindHook()
    sm.log.warning("[TERRAIN OVERRIDE] TRY CHAT BIND HOOK")
    if not commandsLoaded then --Have the commands been loaded yet?
        sm.log.warning("[TERRAIN OVERRIDE] CHAT BIND HOOK BEGIN")
        commandsLoaded = true --Now they have.

        if TERRAINTYPESWITCHENABLED and sm.isHost then
            sm.game.bindChatCommand("/switchTerrain", {}, "cl_onChatCommand", "Open a menu that lets you adjust the terrain.")
        end
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

--When the game script processes the chat command, if it doesn't find
--a match, it sends an event to the world script.
--Here we intercept the event to inject the code for our custom commands.
oldWorldEvent = oldWorldEvent or sm.event.sendToWorld
function sm.event.sendToWorld(world, callback, args)
    --Is this a chat command event? If it is, we can execute the code
    --for our commands.
    if callback == "sv_e_onChatCommand" then
        --Check the command string and implement the command's
        --functionality if there is a match.
        local command = args[1]
        if command == "/switchTerrain" then
            --Send an event over to our GameHook class, where our code is.
            sm.event.sendToTool(g_terrainOverrideGameHook, "sv_switchTerrain", args.player)
        end
    end

    --Make sure to pass the event on, other mods use this method too.
    return oldWorldEvent(world, callback, args)
end