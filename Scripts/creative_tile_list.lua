----------------------------------------------------------------------------------------------------
-- Data
----------------------------------------------------------------------------------------------------

g_barrierTileList = g_barrierTileList or { ["NE"] = {}, ["NW"] = {}, ["SE"] = {}, ["SW"] = {}, ["N"] = {}, ["S"] = {}, ["E"] = {}, ["W"] = {} }
g_desertTileList = g_desertTileList or {}
g_borderTileList =  g_borderTileList  or {}
g_beachTileList = g_beachTileList or { ["InnerCorner"] = {}, ["InnerSide"] = {}, ["OuterCorner"] = {}, ["OuterSide"] = {} }
g_waterTileList =  g_waterTileList or {}
g_terrainTileList = g_terrainTileList or {}

g_useCounts = g_useCounts or {}

-----------------------------------------------------------------------------------------------------

function getWaterTile( x, y, seed )
	local idx = 1 + sm.noise.intNoise2d( x, y, seed ) % #g_waterTileList
	return g_waterTileList[idx]
end

-----------------------------------------------------------------------------------------------------

function getBeachTile( x, y, tileMin, tileMax, seed, outer )
	local direction = ""
	local rotation = 0

	if y == tileMax then
		direction = direction .. "N"
	elseif y == tileMin then
		direction = direction .. "S"
	end

	if x == tileMax then
		direction = direction .. "E"
	elseif x == tileMin then
		direction = direction .. "W"
	end

	local tileList
	if direction == "NW" or direction == "NE" or direction == "SE" or direction == "SW" then
		if outer then
			tileList = "OuterCorner"
			if direction == "NW" then
				rotation = 3
			elseif direction == "NE" then
				rotation = 2
			elseif direction == "SE" then
				rotation = 1
			elseif direction == "SW" then
				rotation = 0
			end
		else
			tileList = "InnerCorner"
			if direction == "NW" then
				rotation = 0
			elseif direction == "NE" then
				rotation = 3
			elseif direction == "SE" then
				rotation = 2
			elseif direction == "SW" then
				rotation = 1
			end
		end
	else
		if outer then
			tileList = "OuterSide"
			if direction == "N" then
				rotation = 2
			elseif direction == "E" then
				rotation = 1
			elseif direction == "S" then
				rotation = 0
			elseif direction == "W" then
				rotation = 3
			end
		else
			tileList = "InnerSide"
			if direction == "N" then
				rotation = 0
			elseif direction == "E" then
				rotation = 3
			elseif direction == "S" then
				rotation = 2
			elseif direction == "W" then
				rotation = 1
			end
		end
	end

	local tile = g_beachTileList[tileList][1 + sm.noise.intNoise2d( x, y, seed ) % #g_beachTileList[tileList]]
	return tile, rotation

end

-----------------------------------------------------------------------------------------------------

function getBarrierTile( x, y, tileMin, tileMax, seed )
	local direction = ""
	if y == tileMax then
		direction = direction .. "N"
	elseif y == tileMin then
		direction = direction .. "S"
	end

	if x == tileMax then
		direction = direction .. "E"
	elseif x == tileMin then
		direction = direction .. "W"
	end

	assert( g_barrierTileList[direction] )
	return g_barrierTileList[direction][1 + sm.noise.intNoise2d( x, y, seed ) % #g_barrierTileList[direction]]
end

-----------------------------------------------------------------------------------------------------

function getDesertTile( x, y, seed )
	local idx = 1 + sm.noise.intNoise2d( x, y, seed ) % #g_desertTileList
	return g_desertTileList[idx]
end

-----------------------------------------------------------------------------------------------------

function getBorderTile( x, y, seed )
	local idx = 1 + sm.noise.intNoise2d( x, y, seed ) % #g_borderTileList
	return g_borderTileList[idx]
end

-----------------------------------------------------------------------------------------------------

function getSuitableTile( x, y, maxSize, seed )
	local size = 0
	local minSize = getGreatestPossibleMinSize( sm.noise.intNoise2d( x, y, seed ) %  maxSize )

	local suitable, lowestUsage = getSuitableTileCount( maxSize, minSize )

	local steps = sm.noise.intNoise2d( x, y, seed ) % suitable

	--step a number of suitable tiles forward and return the last one
	local index = 1
	while index < #g_terrainTileList do
		local uid = g_terrainTileList[index]
		if g_useCounts[tostring(uid)] == lowestUsage then
			size = GetSize( uid )
			if size <= maxSize and size >= minSize then
				if steps > 0 then
					steps = steps - 1
				else
					break
				end
			end
		end

		index = index + 1
	end

	local uid = g_terrainTileList[index]
	g_useCounts[tostring(uid)] = g_useCounts[tostring(uid)] + 1

	return uid
end

---------------------------------------------------------------------------------------------------

function getLargestSuitableTile( x, y, maxSize, seed )
	local size = 0
	local minSize = getGreatestPossibleMinSize(maxSize)

	local suitable, lowestUsage = getSuitableTileCount( maxSize, minSize )

	local steps = sm.noise.intNoise2d( x, y, seed ) % suitable

	--step a number of suitable tiles forward and return the last one
	local index = 1
	while index < #g_terrainTileList do
		local uid = g_terrainTileList[index]
		if g_useCounts[tostring(uid)] == lowestUsage then
			size = GetSize( uid )
			if size <= maxSize and size >= minSize then
				if steps > 0 then
					steps = steps - 1
				else
					break
				end
			end
		end

		index = index + 1
	end

	local uid = g_terrainTileList[index]
	g_useCounts[tostring(uid)] = g_useCounts[tostring(uid)] + 1

	return uid
end

---------------------------------------------------------------------------------------------------

function getSuitableTileCount( maxSize, minSize )
	local suitableTiles = 0
	local lowestUsage = 1000 --Just a big number, no singe tile should be use this many times with the current map size
	local index = 1

	while index < #g_terrainTileList do
		local uid = g_terrainTileList[index]
		local size = GetSize( uid )
		if size <= maxSize and size >= minSize then

			local usage = g_useCounts[tostring(uid)]
			if lowestUsage > usage then

				lowestUsage = usage
				suitableTiles = 1
			elseif usage == lowestUsage then
				suitableTiles = suitableTiles + 1
			end
		end
		index = index + 1
	end

	return suitableTiles, lowestUsage
end

----------------------------------------------------------------------------------------------------

function getGreatestPossibleMinSize( maxSize )
	local minSize = 1
	for index = 1, #g_terrainTileList do
		local uid = g_terrainTileList[index]
		local size = GetSize( uid )
		if size <= maxSize then
			minSize = math.max( minSize, size )
		end
	end

	return minSize
end

----------------------------------------------------------------------------------------------------

function InitTileList()
	-- Barriers
	-- Corners
	g_barrierTileList["NE"][#g_barrierTileList["NE"] + 1] = AddTile( 30000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceNE.tile" )
	g_barrierTileList["NW"][#g_barrierTileList["NW"] + 1] = AddTile( 30001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceNW.tile" )
	g_barrierTileList["SE"][#g_barrierTileList["SE"] + 1] = AddTile( 30002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceSE.tile" )
	g_barrierTileList["SW"][#g_barrierTileList["SW"] + 1] = AddTile( 30003, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceSW.tile" )
	-- North
	g_barrierTileList["N"][#g_barrierTileList["N"] + 1] = AddTile( 31000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceN_01.tile" )
	g_barrierTileList["N"][#g_barrierTileList["N"] + 1] = AddTile( 31001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceN_02.tile" )
	g_barrierTileList["N"][#g_barrierTileList["N"] + 1] = AddTile( 31002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceN_03.tile" )
	-- South
	g_barrierTileList["S"][#g_barrierTileList["S"] + 1] = AddTile( 32000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceS_01.tile" )
	g_barrierTileList["S"][#g_barrierTileList["S"] + 1] = AddTile( 32001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceS_02.tile" )
	g_barrierTileList["S"][#g_barrierTileList["S"] + 1] = AddTile( 32002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceS_03.tile" )
	-- East
	g_barrierTileList["E"][#g_barrierTileList["E"] + 1] = AddTile( 33000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceE_01.tile" )
	g_barrierTileList["E"][#g_barrierTileList["E"] + 1] = AddTile( 33001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceE_02.tile" )
	g_barrierTileList["E"][#g_barrierTileList["E"] + 1] = AddTile( 33002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceE_03.tile" )
	-- West
	g_barrierTileList["W"][#g_barrierTileList["W"] + 1] = AddTile( 34000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceW_01.tile" )
	g_barrierTileList["W"][#g_barrierTileList["W"] + 1] = AddTile( 34001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceW_02.tile" )
	g_barrierTileList["W"][#g_barrierTileList["W"] + 1] = AddTile( 34002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/FenceW_03.tile" )

	-- Desert
	g_desertTileList[#g_desertTileList + 1] = AddTile( 20000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DESERT64_01.tile" )
	g_desertTileList[#g_desertTileList + 1] = AddTile( 20001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DESERT64_02.tile" )
	g_desertTileList[#g_desertTileList + 1] = AddTile( 20002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DESERT64_03.tile" )
	g_desertTileList[#g_desertTileList + 1] = AddTile( 20003, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DESERT64_04.tile" )
	g_desertTileList[#g_desertTileList + 1] = AddTile( 20004, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DESERT64_05.tile" )

	-- Water
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50000, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_01.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50001, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_02.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50002, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_03.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50003, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_04.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50004, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_05.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50005, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_06.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50006, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_07.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50007, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_08.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50008, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_09.tile" )
	g_waterTileList[#g_waterTileList + 1] = AddTile( 50009, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(1111)_10.tile" )

	-- Beach
	-- Outer Corners, desert
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_01.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_02.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_03.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40003, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_04.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40004, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_05.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40005, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_06.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40006, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_07.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40007, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_08.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40008, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_09.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40009, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_10.tile" )
	g_beachTileList["OuterCorner"][#g_beachTileList["OuterCorner"] + 1] = AddTile( 40010, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0001)_11.tile" )
	-- Inner Corners, grass
	g_beachTileList["InnerCorner"][#g_beachTileList["InnerCorner"] + 1] = AddTile( 41000, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0111)_01.tile" )
	g_beachTileList["InnerCorner"][#g_beachTileList["InnerCorner"] + 1] = AddTile( 41001, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0111)_02.tile" )
	g_beachTileList["InnerCorner"][#g_beachTileList["InnerCorner"] + 1] = AddTile( 41002, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0111)_03.tile" )
	g_beachTileList["InnerCorner"][#g_beachTileList["InnerCorner"] + 1] = AddTile( 41003, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0111)_04.tile" )
	g_beachTileList["InnerCorner"][#g_beachTileList["InnerCorner"] + 1] = AddTile( 41004, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0111)_05.tile" )
	g_beachTileList["InnerCorner"][#g_beachTileList["InnerCorner"] + 1] = AddTile( 41005, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0111)_06.tile" )
	-- Inner Side, grass
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42000, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_01.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42001, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_02.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42002, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_03.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42003, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_04.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42004, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_05.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42005, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_06.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42006, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_07.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42007, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_08.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42008, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_09.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42009, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_10.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42010, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_11.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42011, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_12.tile" )
	g_beachTileList["InnerSide"][#g_beachTileList["InnerSide"] + 1] = AddTile( 42012, "$SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_13.tile" )
	-- Not used: $SURVIVAL_DATA/Terrain/Tiles/lake/Lake(0011)_14.tile
	-- Sides, desert
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43000, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_01.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43001, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_02.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43002, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_03.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43003, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_04.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43004, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_05.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43005, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_06.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43006, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_07.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43007, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_08.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43008, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_09.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43009, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_10.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43010, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_11.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43011, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_12.tile" )
	g_beachTileList["OuterSide"][#g_beachTileList["OuterSide"] + 1] = AddTile( 43012, "$GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_13.tile" )
	-- Not used: $GAME_DATA/Terrain/Tiles/CreativeTiles/Auto/DesertLake(0011)_14.tile

	-- Border
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10000, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_04.tile" )
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10001, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_05.tile" )
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10002, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_06.tile" )
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10003, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_07.tile" )
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10004, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_08.tile" )
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10005, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_27.tile" )
	g_borderTileList[#g_borderTileList + 1] = AddTile( 10006, "$SURVIVAL_DATA/Terrain/Tiles/meadow/Meadow_64(1111)_28.tile" )

	-- Standard tiles
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 1, "$GAME_DATA/Terrain/Tiles/CreativeTiles/FOREST256_01.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 2, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_01.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 3, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_02.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 4, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_03.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 5, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_01.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 6, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_02.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 7, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_03.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 8, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_04.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 9, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_01.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 10, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_02.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 11, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_03.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 12, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_04.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 13, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_01.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 14, "$GAME_DATA/Terrain/Tiles/CreativeTiles/HILLS256_01.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 15, "$GAME_DATA/Terrain/Tiles/CreativeTiles/HILLS512_01.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 16, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_01.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 17, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_02.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 18, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_03.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 19, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_04.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 20, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_05.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 21, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_06.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 22, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_07.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 23, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_08.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 24, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_09.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 25, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_10.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 26, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_11.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 27, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_12.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 28, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_13.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 29, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_14.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 30, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_15.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 31, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_16.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 32, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_17.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 33, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_18.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 34, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_19.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 35, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_20.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 36, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_01.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 37, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_02.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 38, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_03.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 39, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_04.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 40, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_05.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 41, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_06.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 42, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_07.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 43, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_08.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 44, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_09.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 45, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_10.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 46, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_11.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 47, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW128_12.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 48, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW256_01.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 49, "$GAME_DATA/Terrain/Tiles/CreativeTiles/START64_01.TILE" )

	-- ^ Initial 1.0.0 tile set ^

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 50, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_05.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 51, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_06.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 52, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_07.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 53, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_04.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 54, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_05.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 55, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_06.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 56, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_07.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 57, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_08.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 58, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_09.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 59, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_10.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 60, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_05.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 61, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_06.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 62, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_07.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 63, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND128_08.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 64, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_08.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 65, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_09.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 66, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_10.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 67, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_11.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 68, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND256_12.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 69, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_02.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 70, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_03.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 71, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_04.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 72, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND512_05.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 73, "$GAME_DATA/Terrain/Tiles/CreativeTiles/GROUND64_11.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 74, "$GAME_DATA/Terrain/Tiles/CreativeTiles/MEADOW64_21.TILE" )

	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 75, "$GAME_DATA/Terrain/Tiles/CreativeTiles/WATER256_01.TILE" )
	g_terrainTileList[#g_terrainTileList + 1] = AddTile( 76, "$GAME_DATA/Terrain/Tiles/CreativeTiles/WATER256_02.TILE" )



	--Some optional custom tiles. Keep in mind, if they have any asset pack dependencies, you need to
	--add those to the mod's dependencies, or else they will not be loaded.
	--Here are the dependencies for the tiles, just copy them into the dependencies list in description.json:
	-- {
	-- 	"fileId" : 2819452871,
	-- 	"localId" : "1eae36e3-aaa6-46b2-b92f-57e1e7811ee3",
	-- 	"name" : "Survival Mode Assets Fix"
	-- },
	-- {
	-- 	"fileId" : 1357816385,
	-- 	"localId" : "4345e76b-f43a-4f9a-b2ea-0f11735e183c",
	-- 	"name" : "Terrain Assets by sKITzo"
	-- },
	-- {
	-- 	"fileId" : 1686374919,
	-- 	"localId" : "54ae755f-6c04-42b2-b6dc-e76b68ffb81d",
	-- 	"name" : "SM Official Items Assets"
	-- },
	-- {
	-- 	"fileId" : 1331879173,
	-- 	"localId" : "740ff0f9-9700-4ace-a980-5099bd3807f4",
	-- 	"name" : "Terrain Assets by Lord Pain"
	-- },
	-- {
	-- 	"fileId" : 1332027099,
	-- 	"localId" : "901cd494-edf7-43e1-9921-2e31550b6ca2",
	-- 	"name" : "Terrain Assets Basics"
	-- },
	-- {
	-- 	"fileId" : 1339396219,
	-- 	"localId" : "bb031b9b-1fdc-431b-a47f-7161d8b1fc76"
	-- }

	--This is also one of the dependencies, but it seems like it was deleted, and will prevent world load.
	--TL;DR: don't add it.
	-- {
	-- 	"fileId" : 2716762412,
	-- 	"localId" : "ded7df34-601b-477d-9afe-3141058a1c35",
	-- 	"name" : "Legend Train Assets"
	-- },

	-- g_terrainTileList[#g_terrainTileList + 1] = AddTile( 77, "$CONTENT_fbb21f26-a82a-4472-a4a8-dc837fd338c7/Aircraft Carrier - X.tile" )
	-- g_terrainTileList[#g_terrainTileList + 1] = AddTile( 78, "$CONTENT_db6fc376-bf15-4ef0-8e8c-d621afeae424/Scraptopia City Airport.tile" )
	-- g_terrainTileList[#g_terrainTileList + 1] = AddTile( 79, "$CONTENT_e7208a0d-860f-4ccb-a765-6a98b1ad6ba7/Gold Mine.tile" )
	-- g_terrainTileList[#g_terrainTileList + 1] = AddTile( 80, "$CONTENT_57a05c09-0ef3-4add-8771-ff956dd5d308/Boat Race.tile" )
	-- g_terrainTileList[#g_terrainTileList + 1] = AddTile( 81, "$CONTENT_eabc56f9-e1f6-46c8-a604-512aeb6b19fb/Five Pebbles iterator Can [Rain World].tile" )




	--Load custom tiles from addons
	local tiles = sm.terrainGeneration.loadGameStorage(TERRAINOVERRIDEMODUUID.."_tileList") or {}
	if #tiles.removed > 0 then
		local shouldRemove = {}
		for k, path in pairs(tiles.removed) do
			shouldRemove[path] = true
		end

		local newTerrainTiles = {}
		for k, uuid in pairs(g_terrainTileList) do
			if shouldRemove[GetPath(uuid)] == nil then
				table.insert(newTerrainTiles, uuid)
			end
		end

		g_terrainTileList = newTerrainTiles
	end

	for k, tilePath in pairs(tiles.added) do
		g_terrainTileList[#g_terrainTileList + 1] = AddTile( nil, tilePath )
	end




	for _, uid in ipairs( g_terrainTileList ) do
		g_useCounts[tostring(uid)] = 0
	end

	for _, uid in ipairs( g_beachTileList ) do
		g_useCounts[tostring(uid)] = 0
	end

	for _, uid in ipairs( g_waterTileList ) do
		g_useCounts[tostring(uid)] = 0
	end

	for _, uid in ipairs( g_desertTileList ) do
		g_useCounts[tostring(uid)] = 0
	end

	for _, uid in ipairs( g_barrierTileList ) do
		g_useCounts[tostring(uid)] = 0
	end
end