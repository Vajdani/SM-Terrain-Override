# Terrain Override mod for Scrap Mechanic

# Info
This is a mod that overrides the terrain to be that of a creative world's, but much larger.
The maximum size for a SM world is 256x256 cells, this mod offers a play area of 254x254 cells. It had to be 2 tiles shorter, or else the world border gate tiles would not be put in the world, and that would look weird.
Due to the world being so large, chunk loading has been enabled, since creative worlds are always fully loaded.

The mod also features functionality for switching between different terrain types, but this is disabled by default due to being unfinished.
The `TERRAINTYPESWITCHENABLED` flag can be toggled in Scripts/GameHook.lua, if you wish to enable it.

# Addons
The mod features addon support, which can:
- **expand** the list of tiles that the game picks from while generating terrain
- **remove** tiles that are being used by the terrain generation.

If you wish to make such an addon, here is what you need to do:
1. Make a new mod in the mod tool.
2. Make a `tileList.json` file in the root folder of the mod.\
The file contains information about added and removed tiles. It also contains any potential dependencies that the added tiles may have.\

Here is an example of an addon file:
```json
{
    "addedTiles": [
        //List of paths to the added tiles.
        
        //Adds the two Farmbot Graveyard tile from Survival.
        "$SURVIVAL_DATA/Terrain/Tiles/poi/FarmbotGraveyard_256_01.tile",
        "$SURVIVAL_DATA/Terrain/Tiles/poi/FarmbotGraveyard_256_02.tile",

        //If you wish to include a user made tile, you will have to refer to
        //it using "$CONTENT_uuid".
        "$CONTENT_e7208a0d-860f-4ccb-a765-6a98b1ad6ba7/Gold Mine.tile",
        "$CONTENT_57a05c09-0ef3-4add-8771-ff956dd5d308/Boat Race.tile"
    ],
    "removedTiles": [
        //List of paths to the removed tiles.

        //Removes the four large tiles from Creative.
        "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_02.TILE",
        "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_03.TILE",
        "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_04.TILE",
        "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_05.TILE",

        //If you wish to remove a user made tile, you will have to refer to
        //it using "$CONTENT_uuid".
        //If you included a tile in the "addedTiles" section, but also included
        //it here, it will be removed as well.
        "$CONTENT_db6fc376-bf15-4ef0-8e8c-d621afeae424/Scraptopia City Airport.tile"
    ],
    "dependencies": [
        //List of dependencies.

        //A dependency object.
        {
            "fileId" : 1331879173, //Workshop file id.
            "localId" : "740ff0f9-9700-4ace-a980-5099bd3807f4", //Uuid of the pack.
            "name" : "Terrain Assets by Lord Pain" //Name of the pack, optional.
        },
        {
            "fileId" : 1339396219,
            "localId" : "bb031b9b-1fdc-431b-a47f-7161d8b1fc76"
        },
        {
            "fileId" : 1357816385,
            "localId" : "4345e76b-f43a-4f9a-b2ea-0f11735e183c",
            "name" : "Terrain Assets by sKITzo"
        }
    ]
}
```

# Forking
If you wish to use this project as a base for your own:
- Don't forget to change the mod's `localId` and `fileId`(just remove it from the file, the mod tool will set it automatically) in `description.json`, and the GameHook autoTool's uuid in `Tools/DataBase/ToolSets/tools.toolset`.
- If you wish to use the default terrain generation script, you will also have to change the mod UUID in `Scripts/terrain_creative_override.lua`