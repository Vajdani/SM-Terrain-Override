TERRAINOVERRIDEMODUUID = "a4a143b1-eaad-4dcc-b0d9-7e426ed26af4"

dofile("$GAME_DATA/scripts/terrain/terrain_creative_celldata.lua")

--The original tile list.
--dofile("$GAME_DATA/scripts/terrain/creative_tile_list.lua")

--The mod's custom tile list. By default, it doesn't have any new tiles, but you can
--find them commented out.
dofile("$CONTENT_"..TERRAINOVERRIDEMODUUID.."/Scripts/creative_tile_list.lua")

dofile("$SURVIVAL_DATA/scripts/terrain/overworld/tile_database.lua")

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

--How many cells wide the water border should be.
local WATER_WIDTH = 12

function Init()
	print( "Initializing creative terrain" )

	--The world's size, minus 4 cells for the beaches, minus the water width.
	BORDER_START = (64 - 4 - WATER_WIDTH) * CELL_SIZE
	BORDER_END = BORDER_START + CELL_SIZE

	BEACH_FIRST_START = BORDER_END
	BEACH_FIRST_END = BEACH_FIRST_START + CELL_SIZE

	WATER_START = BEACH_FIRST_END
	WATER_END = WATER_START + CELL_SIZE * WATER_WIDTH

	BEACH_SECOND_START = WATER_END
	BEACH_SECOND_END = BEACH_SECOND_START + CELL_SIZE

	DESERT_START = BEACH_SECOND_END
	DESERT_END = DESERT_START + CELL_SIZE

	BARRIER_START = DESERT_END
	BARRIER_END = BARRIER_START + CELL_SIZE

	InitTileList()
end

----------------------------------------------------------------------------------------------------

local discardCell = {
	-- [9] = true,
	[10] = true,
	[11] = true,
	[12] = true,
	[13] = true,
	[14] = true,
	[15] = true,
	[16] = true,
}

local function initializeCellData( xMin, xMax, yMin, yMax, seed )
	-- Version history:
	-- 2:	Changes integer 'tileId' to 'uid' from tile uuid
	--		Renamed 'tileOffsetX' -> 'xOffset'
	--		Renamed 'tileOffsetY' -> 'yOffset'
	--		Added 'version'

	-- 1337: Regenerate world for override

	g_cellData = {
		bounds = { xMin = xMin, xMax = xMax, yMin = yMin, yMax = yMax },
		seed = seed,
		-- Per Cell
		uid = (g_cellData or {}).uid or {},
		xOffset = (g_cellData or {}).xOffset or {},
		yOffset = (g_cellData or {}).yOffset or {},
		rotation = (g_cellData or {}).rotation or {},
		version = 1337
	}

	-- Cells
	for cellY = yMin, yMax do
		if g_cellData.uid[cellY] == nil or discardCell[math.abs(cellY)] == true then
			g_cellData.uid[cellY] = {}
			g_cellData.xOffset[cellY] = {}
			g_cellData.yOffset[cellY] = {}
			g_cellData.rotation[cellY] = {}
		end

		for cellX = xMin, xMax do
			if g_cellData.uid[cellY][cellX] == nil or discardCell[math.abs(cellX)] == true then
				g_cellData.uid[cellY][cellX] = sm.uuid.getNil()
				g_cellData.xOffset[cellY][cellX] = 0
				g_cellData.yOffset[cellY][cellX] = 0
				g_cellData.rotation[cellY][cellX] = 0
			end
		end
	end
end

function Create( xMin, xMax, yMin, yMax, seed )
	print( "Create creative terrain" )
	print( "Bounds X: ["..xMin..", "..xMax.."], Y: ["..yMin..", "..yMax.."]" )
	print( "Seed: "..seed )

	--The beaches, plus the water.
	local graphicsCellPadding = 4 + WATER_WIDTH
	xMin = xMin - graphicsCellPadding
	xMax = xMax + graphicsCellPadding
	yMin = yMin - graphicsCellPadding
	yMax = yMax + graphicsCellPadding

	print( "Initializing cell data" )
	initializeCellData( xMin, xMax, yMin, yMax, seed )

	print( "Generating world..." )
	CreateBorders( xMin, xMax, yMin, yMax, seed )

	--Aply the padding in reverse to get the real generated area.
	GenerateWorld(
		xMin + graphicsCellPadding,
		xMax - graphicsCellPadding,
		yMin + graphicsCellPadding,
		yMax - graphicsCellPadding,
		seed
	)

	print( "Total cells: "..( xMax - xMin + 1 ) * ( yMax - yMin + 1 ) )

	sm.terrainData.save( g_cellData )
end



function UpgradeCellData( cellData )
	sm.log.info( "UpgradeCellData - version: "..tostring( cellData.version or 1 ) )
	local upgraded = false
	-- 1 to 2
	if ( cellData.version or 1 ) < 2 then
		cellData.xOffset = cellData.tileOffsetX 		-- rename offset x table
		cellData.tileOffsetX = nil

		cellData.yOffset = cellData.tileOffsetY 		-- rename offset y table
		cellData.tileOffsetY = nil

		if cellData.uid == nil then
			cellData.uid = {}							-- add uid table
		end

		for cellY = cellData.bounds.yMin, cellData.bounds.yMax do
			if cellData.uid[cellY] == nil then
				cellData.uid[cellY] = {}				-- add uid table
			end

			for cellX = cellData.bounds.xMin, cellData.bounds.xMax do
				if cellData.uid[cellY][cellX] == nil then
					cellData.uid[cellY][cellX] = {}		-- add uid table
				end
				local id = cellData.tileId[cellY][cellX]
				local uid = GetLegacyUpgrade( id )
				if not sm.uuid.isNil( uid ) then
					cellData.uid[cellY][cellX] = uid -- (int) tileId -> (uuid) uid
				else
					cellData.uid[cellY][cellX] = sm.uuid.getNil()
				end
			end
		end
		cellData.version = 2
		upgraded = true
	end

	if cellData.version < 1337 then
		Create( -64, 63, -64, 63, cellData.seed )

		cellData.version = 1337
		upgraded = true
	end

	if upgraded then sm.log.info( "	- Upgraded to version "..tostring( cellData.version ) ) else sm.log.info( "	- No upgrade needed" ) end
	return upgraded
end



----------------------------------------------------------------------------------------------------

function Load()
	print( "Loading terrain" )
	if sm.terrainData.exists() then
		g_cellData = sm.terrainData.load()
		if UpgradeCellData( g_cellData ) then
			sm.terrainData.save( g_cellData )
		end
		return true
	end
	print( "No terrain data found" )
	return false
end

----------------------------------------------------------------------------------------------------
-- Generator API Getters
----------------------------------------------------------------------------------------------------

function GetCellTileUidAndOffset( cellX, cellY )
	if InsideCellBounds( cellX, cellY ) then
		return	g_cellData.uid[cellY][cellX],
				g_cellData.xOffset[cellY][cellX],
				g_cellData.yOffset[cellY][cellX]
	end
	return sm.uuid.getNil(), 0, 0
end

----------------------------------------------------------------------------------------------------

function GetHeightAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )

	local rx, ry = InverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )

	local height = sm.terrainTile.getHeightAt( uid, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )

	return height
end

----------------------------------------------------------------------------------------------------

function GetColorAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )

	local rx, ry = InverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )

	local r, g, b = sm.terrainTile.getColorAt( uid, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )

	local noise = sm.noise.octaveNoise2d( x / 8, y / 8, 5, 45 )
	local brightness = noise * 0.25 + 0.75
	local color = { r, g, b }
	
	local desertColor = { 255 / 255, 171 / 255, 111 / 255 }

	local maxDist = math.max( math.abs(x), math.abs(y) )
	if maxDist >= BARRIER_END then
		color[1] = desertColor[1]
		color[2] = desertColor[2]
		color[3] = desertColor[3]
	elseif maxDist >= BARRIER_START then
		local fade = ( maxDist - BARRIER_START ) / ( BARRIER_END - BARRIER_START )
		color[1] = 1.0 + ( desertColor[1] - 1.0 ) * fade
		color[2] = 1.0 + ( desertColor[2] - 1.0 ) * fade
		color[3] = 1.0 + ( desertColor[3] - 1.0 ) * fade
	elseif maxDist >= DESERT_START then
		color[1] = 1
		color[2] = 1
		color[3] = 1
	end

	return color[1] * brightness, color[2] * brightness, color[3] * brightness
end

----------------------------------------------------------------------------------------------------

function GetMaterialAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )

	local rx, ry = InverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )

	local mat1, mat2, mat3, mat4, mat5, mat6, mat7, mat8 = sm.terrainTile.getMaterialAt( uid, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )

	local maxDist = math.max( math.abs(x), math.abs(y) )
	if maxDist >= BARRIER_END then
		mat1 = 1.0
	elseif maxDist >= BARRIER_START and maxDist <= BARRIER_END then
		mat2, mat3, mat4, mat5, mat6, mat7, mat8 = 0, 0, 0, 0, 0, 0, 0, 0
		local fade = ( maxDist - BARRIER_START ) / ( BARRIER_END - BARRIER_START )
		mat1 = 1.0
		mat2 = 1.0 - fade
	elseif maxDist >= DESERT_START then
		mat1, mat2, mat3, mat4, mat5, mat6, mat7, mat8 = 0, 0, 0, 0, 0, 0, 0, 0
		mat2 = 1.0
	end

	return mat1, mat2, mat3, mat4, mat5, mat6, mat7, mat8
end

----------------------------------------------------------------------------------------------------

function GetClutterIdxAt( x, y )
	local cellX = math.floor( x / ( CELL_SIZE * 2 ) )
	local cellY = math.floor( y / ( CELL_SIZE * 2 ) )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )

	local rx, ry = InverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE * 2, y - cellY * CELL_SIZE * 2, CELL_SIZE * 2 - 1 )

	local clutterIdx = sm.terrainTile.getClutterIdxAt( uid, tileCellOffsetX, tileCellOffsetY, rx, ry )
	return clutterIdx
end

----------------------------------------------------------------------------------------------------

function GetEffectMaterialAt( x, y )
	local mat0, mat1, mat2, mat3, mat4, mat5, mat6, mat7 = GetMaterialAt( x, y, 0 )

	local materialWeights = {}
	materialWeights["Grass"] = math.max( mat4, mat7 )
	materialWeights["Rock"] = math.max( mat0, mat2, mat5 )
	materialWeights["Dirt"] = math.max( mat3, mat6 )
	materialWeights["Sand"] = math.max( mat1 )
	local weightThreshold = 0.25
	local selectedKey = "Grass"

	for key, weight in pairs(materialWeights) do
		if weight > materialWeights[selectedKey] and weight > weightThreshold then
			selectedKey = key
		end
	end

	return selectedKey
end

----------------------------------------------------------------------------------------------------

local water_asset_uuid = sm.uuid.new( "990cce84-a683-4ea6-83cc-d0aee5e71e15" )

function GetAssetsForCell( cellX, cellY, lod )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		local assets = sm.terrainTile.getAssetsForCell( uid, tileCellOffsetX, tileCellOffsetY, lod )
		for i,asset in ipairs(assets) do
			local rx, ry = RotateLocal( cellX, cellY, asset.pos.x, asset.pos.y )

			-- Water rotation
			if asset.uuid == water_asset_uuid then
				asset.pos = sm.vec3.new( rx, ry, asset.pos.z )
				asset.rot = sm.quat.new( 0.7071067811865475, 0.0, 0.0, 0.7071067811865475 )
			else
				asset.pos = sm.vec3.new( rx, ry, asset.pos.z )
				asset.rot = GetRotationQuat( cellX, cellY ) * asset.rot
			end
		end

		return assets
	end
	return {}
end

----------------------------------------------------------------------------------------------------

function GetNodesForCell( cellX, cellY )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		local hasReflectionProbe = false

		local tileNodes = sm.terrainTile.getNodesForCell( uid, tileCellOffsetX, tileCellOffsetY )
		for i, node in ipairs( tileNodes ) do
			local rx, ry = RotateLocal( cellX, cellY, node.pos.x, node.pos.y )

			node.pos = sm.vec3.new( rx, ry, node.pos.z )
			node.rot = GetRotationQuat( cellX, cellY ) * node.rot

			RotateLocalWaypoint( cellX, cellY, node )

			hasReflectionProbe = hasReflectionProbe or ValueExists( node.tags, "REFLECTION" )
		end

		if not hasReflectionProbe then
			local x = ( cellX + 0.5 ) * CELL_SIZE
			local y = ( cellY + 0.5 ) * CELL_SIZE
			local node = {}
			node.pos = sm.vec3.new( 32, 32, GetHeightAt( x, y, 0 ) + 4 )
			node.rot = sm.quat.new( 0.707107, 0, 0, 0.707107 )
			node.scale = sm.vec3.new( 64, 64, 64 )
			node.tags = { "REFLECTION" }
			tileNodes[#tileNodes + 1] = node
		end

		return tileNodes
	end
	return {}
end

----------------------------------------------------------------------------------------------------

function GetHarvestablesForCell( cellX, cellY, size )
	if not InsideBounds( cellX, cellY, BORDER_START ) then
		-- No harvestables near the border
		return {}
	end
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		-- Load harvestables from cell
		local harvestables = sm.terrainTile.getHarvestablesForCell( uid, tileCellOffsetX, tileCellOffsetY, size )
		for _, harvestable in ipairs( harvestables ) do
			local rx, ry = RotateLocal( cellX, cellY, harvestable.pos.x, harvestable.pos.y )

			harvestable.pos = sm.vec3.new( rx, ry, harvestable.pos.z )
			harvestable.rot = GetRotationQuat( cellX, cellY ) * harvestable.rot
		end

		return harvestables
	end
	return {}
end

----------------------------------------------------------------------------------------------------

function GetDecalsForCell( cellX, cellY )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		local cellDecals = sm.terrainTile.getDecalsForCell( uid, tileCellOffsetX, tileCellOffsetY )
		for _, decal in ipairs(cellDecals) do
			local rx, ry = RotateLocal( cellX, cellY, decal.pos.x, decal.pos.y )

			decal.pos = sm.vec3.new( rx, ry, decal.pos.z )
			decal.rot = GetRotationQuat( cellX, cellY ) * decal.rot
		end

		return cellDecals
	end

	return {}
end

----------------------------------------------------------------------------------------------------

function GetCreationsForCell( cellX, cellY )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		local cellCreations = sm.terrainTile.getCreationsForCell( uid, tileCellOffsetX, tileCellOffsetY )
		for i,creation in ipairs( cellCreations ) do
			local rx, ry = RotateLocal( cellX, cellY, creation.pos.x, creation.pos.y )

			creation.pos = sm.vec3.new( rx, ry, creation.pos.z )
			creation.rot = GetRotationQuat( cellX, cellY ) * creation.rot
		end

		return cellCreations
	end

	return {}
end

----------------------------------------------------------------------------------------------------
-- Tile Reader Path Getter
----------------------------------------------------------------------------------------------------

function GetTilePath( uid )
	if not uid:isNil() then
		return GetPath( uid )
	end
	return ""
end
