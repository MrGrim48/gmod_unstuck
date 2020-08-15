--[[
sv_unstuck_func.lua

--]]

// The queue of players to unstuck
Unstuck.ToUnstuck = {}

--[[------------------------------------------------
	Name: Unstuck.Queue()
	Desc: Queue a player to be unstuck.
--]]------------------------------------------------
local color = Color(255,150,150) 
function Unstuck.Queue( ply )
	
	// Return if the player is already in the queue
	if table.HasValue( Unstuck.ToUnstuck, ply ) then return end
	
	Unstuck.ToUnstuck[#Unstuck.ToUnstuck + 1] = ply
	
	local minBound, maxBound = ply:GetHull()	
	Unstuck.DebugEvent( 
		ply, 
		Unstuck.Enumeration.Debug.COMMAND_ADD, 
		Unstuck.Enumeration.Debug.NOUN_BOX, 
		ply:GetPos()+minBound, 
		ply:GetPos()+maxBound, 
		color
	)
	
	return true
	
end

--[[------------------------------------------------
	Name: SpawnPlayer()
	Desc: Called when the unstuck function fails to 
		find a suitable position for the player.
--]]------------------------------------------------
local function SpawnPlayer( ply )
	
	// Return if the player is not valid
	if not IsValid(ply) then return end
	
	// Respawn the player if enabled in the configuration
	if Unstuck.Configuration.RespawnOnFail then
	
		// Set a timer or repawn instantly
		if Unstuck.Configuration.RespawnTimer > 0 then
			ply:UnstuckMessage( Unstuck.Enumeration.Message.RESPAWNING )
			timer.Simple( Unstuck.Configuration.RespawnTimer, function()
				if ply:Alive() then
					ply:Spawn()
				else
					ply:UnstuckMessage( Unstuck.Enumeration.Message.RESPAWN_FAILED )
				end
			end )
		else
			ply:Spawn()
		end
	end
	
end

--[[------------------------------------------------
	Name: GetSurroundingTiles()
	Desc: Returns the positions surrounding 
		the given position based on the 'MinCheckRange'
--]]------------------------------------------------
local function GetSurroundingTiles( ply, pos )

	local tiles = {}
	local x, y, z
	local minBound, maxBound = ply:GetHull()
	local checkRange = math.max(Unstuck.Configuration.MinCheckRange, maxBound.x, maxBound.y)
	
	for z = -1, 1, 1 do
		for y = -1, 1, 1 do
			for x = -1, 1, 1 do
				local testTile = Vector(x,y,z)
				testTile:Mul( checkRange )
				local tilePos = pos + testTile
				tiles[#tiles + 1] = tilePos
			end
		end
	end
	
	return tiles

end

--[[------------------------------------------------
	Name: GetClearPaths()
	Desc: Returns positions that pass a traceline testPos
		from given position to table of positions.
--]]------------------------------------------------
local color2 = Color( 255,0,0 ) 
local function GetClearPaths( ply, pos, tiles )

	local clearPaths = {}

	// Trace to the positions to ensure we don't start getting out of the map
	local filter = player.GetAll()
	table.Add( filter, ents.FindByClass( "prop_physics" ) )
	table.Add( filter, ents.FindByClass( "prop_physics_multiplayer" ) )
	table.Add( filter, ents.FindByClass( "ph_prop" ) )
	table.Add( filter, ents.FindByClass( "func_door" ) )
	table.Add( filter, ents.FindByClass( "prop_door_rotating" ) )
	table.Add( filter, ents.FindByClass( "func_door_rotating" ) )
	
	for _, tile in pairs( tiles ) do
		local tr = util.TraceLine({
			start = pos,
			endpos = tile,
			filter = filter,
			mask = MASK_PLAYERSOLID
		})
		
		if not tr.Hit and util.IsInWorld(tile) then
			Unstuck.DebugEvent( 
				ply, 
				Unstuck.Enumeration.Debug.COMMAND_ADD, 
				Unstuck.Enumeration.Debug.NOUN_LINE, 
				pos, 
				tile, 
				color2
			)
			
			clearPaths[#clearPaths + 1] = tile
		end
	end
	
	return clearPaths
	
end

--[[------------------------------------------------
	Name: FindNewPos()
	Desc: 
--]]------------------------------------------------
local color3 = Color( 255,255,0 ) 
local function FindNewPos( ply, pos, iterNum )
	
	coroutine.yield()
	local surroundingTiles = GetSurroundingTiles( ply, pos )
	coroutine.yield()
	local clearPaths = GetClearPaths( ply, pos, surroundingTiles )	
	
	// We check if we can move the player to any of these positions.
	local minBound, maxBound = ply:GetHull()
	for _, tile in pairs( clearPaths ) do
		coroutine.yield()
		
		if Unstuck.CollisionBoxClear( ply, tile, minBound, maxBound ) then
			Unstuck.DebugEvent( 
				ply, 
				Unstuck.Enumeration.Debug.COMMAND_ADD, 
				Unstuck.Enumeration.Debug.NOUN_BOX, 
				tile + minBound, 
				tile + maxBound, 
				color3
			)	
			
			ply:SetPos( tile )
			ply:UnstuckMessage( Unstuck.Enumeration.Message.UNSTUCK )
			coroutine.yield( Unstuck.Enumeration.PositionTesting.PASSED )
		end
	end
	
	
	// Check that we can start a new iteration
	if (iterNum + 1) > Unstuck.Configuration.MaxIteration then
		coroutine.yield( Unstuck.Enumeration.PositionTesting.FAILED )
	end
	
	
	// If no positions are found, we create a new iteration at each of the clear paths.
	for _, tile in pairs( clearPaths ) do
		coroutine.yield()
		
		local result = Unstuck.CoroutineNewPos( ply, tile, iterNum+1 )
		
		// If a position is found, return a success to end the loop
		if result == Unstuck.Enumeration.PositionTesting.PASSED then
			coroutine.yield( Unstuck.Enumeration.PositionTesting.PASSED )
		end
	end
	
	
	// Return FAILED if no positions are found
	coroutine.yield( Unstuck.Enumeration.PositionTesting.FAILED )
	
end

--[[------------------------------------------------
	Name: Unstuck.CoroutineNewPos()
	Desc: Creates a new coroutine for each iteration of the FindNewPos function.
--]]------------------------------------------------
function Unstuck.CoroutineNewPos( ply, pos, iterNum )

	local newPosCoroutine = coroutine.create( FindNewPos )
	local NoError, NewPosResult
	
	// Repeat until a Pass or Fail is returned or until the end of the iteration.
	repeat
		NoError, NewPosResult = coroutine.resume( newPosCoroutine, ply, pos, iterNum )
	until ( NewPosResult == Unstuck.Enumeration.PositionTesting.FAILED 
		or NewPosResult == Unstuck.Enumeration.PositionTesting.PASSED
		or not NoError )
		
	return NewPosResult
	
end

--[[------------------------------------------------
	Name: Think()
	Desc: Creates the coroutine and processes the queue to unstuck players.
--]]------------------------------------------------
local function Think()
	
	for key, ply in pairs( Unstuck.ToUnstuck ) do
		if IsValid( ply ) then			
			local result = Unstuck.CoroutineNewPos( ply, ply:GetPos(), 1 )
			
			if result == Unstuck.Enumeration.PositionTesting.FAILED then
				ply:UnstuckMessage( Unstuck.Enumeration.Message.FAILED )
				SpawnPlayer( ply )
			end
			
			// Remove the player from the queue
			Unstuck.ToUnstuck[key] = nil
		end
	end

end
hook.Add( "Think", "Unstuck.Think", Think )
