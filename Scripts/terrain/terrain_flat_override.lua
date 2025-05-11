dofile( "$SURVIVAL_DATA/Scripts/terrain/terrain_util2.lua" )

----------------------------------------------------------------------------------------------------

local function directionToUuid( direction )
	return sm.uuid.generateNamed( sm.uuid.new( "82b89df0-55ce-4aad-bb18-5c1395689332" ), direction )
end

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

function Init()
	print( "Initializing flat creative terrain generator" )
	
	-- Init fence
	g_fenceTileList = {}

	--	Corners
	g_fenceTileList[tostring( directionToUuid( "NE" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceNE.tile"
	g_fenceTileList[tostring( directionToUuid( "NW" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceNW.tile"
	g_fenceTileList[tostring( directionToUuid( "SE" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceSE.tile"
	g_fenceTileList[tostring( directionToUuid( "SW" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceSW.tile"

	--	North
	g_fenceTileList[tostring( directionToUuid( "N" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceN_01.tile"

	--	South
	g_fenceTileList[tostring( directionToUuid( "S" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceS_01.tile"

	--	East
	g_fenceTileList[tostring( directionToUuid( "E" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceE_01.tile"

	--	West
	g_fenceTileList[tostring( directionToUuid( "W" ) )] = "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/Flatterrain_FenceW_01.tile"
	
end

----------------------------------------------------------------------------------------------------

local function writeTile( uid, xPos, yPos, size, rotation )
	assert( type( uid ) == "Uuid" )
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local cellX = x + xPos
			local cellY = y + yPos
			g_cellData.uid[cellY][cellX] = uid
			g_cellData.rotation[cellY][cellX] = rotation

			if rotation == 1 then
				g_cellData.xOffset[cellY][cellX] = y
				g_cellData.yOffset[cellY][cellX] = ( size - 1 ) - x
			elseif rotation == 2 then
				g_cellData.xOffset[cellY][cellX] = ( size - 1 ) - x
				g_cellData.yOffset[cellY][cellX] = ( size - 1 ) - y
			elseif rotation == 3 then
				g_cellData.xOffset[cellY][cellX] = ( size - 1 ) - y
				g_cellData.yOffset[cellY][cellX] = x
			else
				g_cellData.xOffset[cellY][cellX] = x
				g_cellData.yOffset[cellY][cellX] = y
			end
		end
	end
end

local function createFence( xMin, xMax, yMin, yMax, padding )
	local _xMin = xMin + padding;
	local _xMax = xMax - padding;

	local _yMin = yMin + padding;
	local _yMax = yMax - padding;

	for cellY = _yMin, _yMax do
		for cellX = _xMin, _xMax do
			if cellX == _xMin or cellX == _xMax or cellY == _yMin or cellY == _yMax then
				local direction = ""
				if cellY == _xMax then
					direction = direction .. "N"
				elseif cellY == _xMin then
					direction = direction .. "S"
				end
				
				if cellX == _xMax then
					direction = direction .. "E"
				elseif cellX == _xMin then
					direction = direction .. "W"
				end
				
				local uid = directionToUuid( direction )
				writeTile( uid, cellX, cellY, 1, 0 )
			end
		end
	end
end

local function initializeCellData( xMin, xMax, yMin, yMax, seed )
	g_cellData = {
		bounds = { xMin = xMin, xMax = xMax, yMin = yMin, yMax = yMax },
		seed = seed,
		-- Per Cell
		uid = {},
		xOffset = {},
		yOffset = {},
		rotation = {}
	}

	-- Cells
	for cellY = yMin, yMax do
		g_cellData.uid[cellY] = {}
		g_cellData.xOffset[cellY] = {}
		g_cellData.yOffset[cellY] = {}
		g_cellData.rotation[cellY] = {}

		for cellX = xMin, xMax do
			g_cellData.uid[cellY][cellX] = sm.uuid.getNil()
			g_cellData.xOffset[cellY][cellX] = 0
			g_cellData.yOffset[cellY][cellX] = 0
			g_cellData.rotation[cellY][cellX] = 0
		end
	end
end

function Create( xMin, xMax, yMin, yMax, seed )

	print( "Create creative flat" )
	print( "Bounds X: [" .. xMin .. ", " .. xMax .. "], Y: [" .. yMin .. ", " .. yMax .. "]" )
	print( "Seed: "..seed )

	local graphicsCellPadding = 1
	xMin = xMin - graphicsCellPadding
	xMax = xMax + graphicsCellPadding
	yMin = yMin - graphicsCellPadding
	yMax = yMax + graphicsCellPadding

	print( "Initializing cell data" )
	initializeCellData( xMin, xMax, yMin, yMax, seed )

	if graphicsCellPadding > 0 then
		print( "Generating world..." )
		createFence( xMin, xMax, yMin, yMax, graphicsCellPadding - 1 )
	end

	print( "Total cells: " .. ( xMax - xMin + 1 ) * ( yMax - yMin + 1 ) )
end

----------------------------------------------------------------------------------------------------

function Load()
	return false
end

----------------------------------------------------------------------------------------------------

local function clamp( v, min, max )
	return math.min( math.max( min, v ), max )
end

local function grassNoise( x, y )
	local noice1 = clamp( clamp( (sm.noise.octaveNoise2d( x / 8, y / 8, 3, 45 ) * 3.5 ) , 0, 1 ) * 1.5, 0, 1 )
	local sub = 1.0 - clamp( ( sm.noise.octaveNoise2d( x * 0.1, y * 0.1, 6, 72834 ) + 0.2 ) * 100, 0, 1 )

	local res = clamp( noice1 - sub, 0, 1 )
	if res < 0.8 then
		res = clamp(  res -  clamp( sm.noise.octaveNoise2d( x * 0.3, y * 0.3, 1, 54353 ) * 6.0, 0, 1 ), 0 , 1 )
	end

	return res
end


local function grassNoise2( grass, x, y )
	local noice1 = clamp( clamp( (sm.noise.octaveNoise2d( x * 0.1, y * 0.1, 1, 34534 )) , 0, 1 ), 0, 1 )
	return noice1 * grass
end


local function dirt1Noise( x, y )
	return 1 - clamp( ( sm.noise.octaveNoise2d( x / 6, y / 6, 3, 9906 ) + 0.8 ) * 0.9, 0, 1 )
end

local function dirt2Noise( x, y )
	local noice1 = clamp( clamp( (sm.noise.octaveNoise2d( x / 4, y / 4, 3, 123 ) * 3.5) , 0, 1 ) * 1.5, 0, 1 )
	local sub = 1.0 - clamp( ( sm.noise.octaveNoise2d( x * 0.2, y * 0.2, 6, 6783 ) + 0.2 ) * 20, 0, 1 )

	local res = clamp( noice1 - sub, 0, 1 )
	if res < 0.8 then
		res = clamp( res - clamp( sm.noise.octaveNoise2d( x, y, 1, 456451 ) * 6.0, 0, 1 ), 0 , 1 )
	end
	return res
end


----------------------------------------------------------------------------------------------------
-- Generator API Getters
----------------------------------------------------------------------------------------------------

function GetCellTileUidAndOffset( cellX, cellY )
	if InsideCellBounds( cellX, cellY ) then
		return 	g_cellData.uid[cellY][cellX],
				g_cellData.xOffset[cellY][cellX],
				g_cellData.yOffset[cellY][cellX]
	end
	return sm.uuid.getNil(), 0, 0
end

----------------------------------------------------------------------------------------------------

function GetHeightAt( x, y, lod )
	return 0
end

----------------------------------------------------------------------------------------------------

function GetColorAt( x, y, lod )

	local noise1 = sm.noise.octaveNoise2d( x / 8, y / 8, 4, 8167 ) * 0.5 + 0.5

	local c1 = sm.color.new( 0xffffffff)
	local c2 = sm.color.new( 0xddbaaaff)

	local color = c1 * noise1 + c2 * ( 1 - noise1 )

	local noise2 = sm.noise.octaveNoise2d( x / 4, y / 4, 5, 45 )
	local brightness = noise2 * 0.15 + 0.75

	local grass = grassNoise( x, y )
	
	local grassColor1 = sm.color.new( 0xc78264ff )
	local grassColor2 = sm.color.new( 0xc78264ff )
	noise1 = noise1 * 2.0

	local grassColor = grassColor1 * noise1 + grassColor2 * ( 1 - noise1 )

	color = grassColor * grass + color * ( 1 - grass )

	return color.r * brightness, color.g * brightness, color.b * brightness
end

----------------------------------------------------------------------------------------------------

function GetMaterialAt( x, y, lod )
	local dirt1 = dirt1Noise( x, y )
	local dirt2 = dirt2Noise( x, y )

	local grass1 = grassNoise( x, y )
	local grass2 = grassNoise2( grass1, x, y )
	
	return clamp( dirt2-(grass1+grass2), 0, 1 ), clamp( dirt1-(grass1+grass2), 0, 1 ), grass1, grass2, 0, 0, 0, 0
end

----------------------------------------------------------------------------------------------------

function GetClutterIdxAt( x, y )
	local grass = grassNoise( x/2, y/2 )
	local off = grass * ( ( 0.5 - clamp( sm.noise.octaveNoise2d( x * 0.4, y * 0.4, 1, 54353 ), 0, 1 ) ) * 4.0 )
	if grass < 0.2 then
		off = off - 0.5
	end

	if grass + off >= 0.5 then
		if grass < 0.33 then
			return 1
		elseif off < 0.75 then
			return 15
		else
			return 9
		end
	end
	return -1
end

----------------------------------------------------------------------------------------------------

function GetAssetsForCell( cellX, cellY, lod )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		local assets = sm.terrainTile.getAssetsForCell( uid, tileCellOffsetX, tileCellOffsetY, lod )
		for _,asset in ipairs(assets) do
			local rx, ry = RotateLocal( cellX, cellY, asset.pos.x, asset.pos.y )

			asset.pos = sm.vec3.new( rx, ry, asset.pos.z )
			asset.rot = GetRotationQuat( cellX, cellY ) * asset.rot
		end
		return assets
	end
	return {}
end

----------------------------------------------------------------------------------------------------

function GetEffectMaterialAt( x, y )
	return "Sand"
end

----------------------------------------------------------------------------------------------------

function GetKinematicsForCell( cellX, cellY, lod )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	local kinematics = sm.terrainTile.getKinematicsForCell( uid, tileCellOffsetX, tileCellOffsetY, lod )
	for _, kinematic in ipairs( kinematics ) do
		local rx, ry = RotateLocal( cellX, cellY, kinematic.pos.x, kinematic.pos.y )
		kinematic.pos = sm.vec3.new( rx, ry, kinematic.pos.z )
		kinematic.rot = GetRotationQuat( cellX, cellY ) * kinematic.rot
	end
	return kinematics
end

----------------------------------------------------------------------------------------------------
-- Tile Reader Path Getter
----------------------------------------------------------------------------------------------------

function GetTilePath( uid )
	if not uid:isNil() and g_fenceTileList[tostring( uid )] then
		return g_fenceTileList[tostring( uid )]
	end
	return ""
end
