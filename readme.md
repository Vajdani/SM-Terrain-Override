# Terrain Override mod for Scrap Mechanic

# Info
This is a mod that overrides the terrain to be that of a creative world's, but much larger.
The maximum size for a SM world is 256x256 cells, this mod offers a play area of 254x254 cells. It had to be 2 tiles shorter, or else the world border gate tiles would not be put in the world, and that would look weird.
Due to the world being so large, chunk loading has been enabled, since creative worlds are always fully loaded.

The mod also features functionality for switching between different terrain types, but this is disabled by default due to being unfinished.
The **TERRAINTYPESWITCHENABLED** flag can be toggled in Scripts/GameHook.lua, if you wish to enable it.

# Addons
The mod features addon support, which can:
- expand the list of tiles that the game picks from while generating terrain
- **remove** tiles that are being used by the terrain generation.

If you wish to make such an addon, here is what you need to do:
- Make a new mod in the mod tool.
- Make a **tileList.json** file in the root folder of the mod.
- 

Don't forget to change the mod's UUID in description.json, and the GameHoook autoTool's uuid in Tools/DataBase/ToolSets/tools.toolset.
If you wish to use the default terrain generation script, you will also have to change the mod UUID in Scripts/terrain_creative_override.lua