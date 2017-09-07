--[[
sv_unstuck_func.lua

--]]


local function SpawnPlayer( ply )
	if IsValid(ply) then
		if ply:Alive() then
			ply:Spawn()
		else
			ply:UnstuckMessage( Unstuck.Enumeration.Message.RESPAWN_FAILED )
		end
	end
end

--[[------------------------------------------------
	Name: LoopData()
	Desc: If another layer exists within the data table, 
			it will call LoopData on that data. Inception.
--]]------------------------------------------------
local function LoopData( ply, data, depth )
	
	if !data then return end
	if data.data and depth < Unstuck.Configuration.MaxDepth then --If Another layer exists and less than max depth
		if LoopData( ply, data.data, depth+1 ) then
			data.data = nil
		end
	else
		local result = Unstuck.FindNewPos( ply, data )
		if result == Unstuck.Enumeration.PositionTesting.PASSED then
			Unstuck.ToUnstuck[ply] = nil
		elseif result == Unstuck.Enumeration.PositionTesting.FAILED then
			return true
		end
	
		if Unstuck.ToUnstuck[ply] and !Unstuck.ToUnstuck[ply].data then
			Unstuck.ToUnstuck[ply] = nil
			ply:UnstuckMessage( Unstuck.Enumeration.Message.FAILED )
			
			if Unstuck.Configuration.RespawnOnFail then
				if Unstuck.Configuration.RespawnTimer > 0 then
					ply:UnstuckMessage( Unstuck.Enumeration.Message.RESPAWNING )
					timer.Simple( Unstuck.Configuration.RespawnTimer, function()
						SpawnPlayer( ply )
					end )
				else
					SpawnPlayer( ply )
				end
			end
		end
	end
	
end

--[[------------------------------------------------
	Name: Think()
	Desc: Spreads the unstuck check with the use of the think hook.
		This should minimize the performance impact on the server.
--]]------------------------------------------------
function Unstuck.Think()

	for ply, data in pairs( Unstuck.ToUnstuck ) do
		LoopData( ply, data, 1 )
	end

end
hook.Add( "Think", "Unstuck.Think", Unstuck.Think )

--[[------------------------------------------------
	Name: FindNewPos()
	Desc: Attempts to find a new position to tp to.
		Returns PASSED if there is a viable postion.
		Returns FAILED if no nearby positions available.
		Creates a new layer of checking if possible.
--]]------------------------------------------------
function Unstuck.FindNewPos( ply, data )
	
	local minBound, maxBound = ply:GetHull()
	local range = { x=32, y=32, z=32 }
	local testPos
	
	-- Filter is for the trace line. Further checks will be made if the trace line passes.
	local filter = player.GetAll()
	table.Add( filter, ents.FindByClass( "prop_physics" ) )
	table.Add( filter, ents.FindByClass( "prop_physics_multiplayer" ) )
	table.Add( filter, ents.FindByClass( "ph_prop" ) )
	table.Add( filter, ents.FindByClass( "ph_dummy" ) )
	table.Add( filter, ents.FindByClass( "func_door" ) )
	table.Add( filter, ents.FindByClass( "prop_door_rotating" ) )
	table.Add( filter, ents.FindByClass( "func_door_rotating" ) )
	
	-- Attempt to ignore previously checked positions
	repeat
		if data.x <= range.x then
			if data.x >= 0 then data.x = data.x + range.x end
			data.x = -data.x 
		elseif data.y <= range.y then
			data.x = 0
			if data.y >= 0 then data.y = data.y + range.y end
			data.y = -data.y
		elseif data.z <= range.z then
			data.y = 0
			if data.z >= 0 then data.z = data.z + range.z end
			data.z = -data.z
		end
		
		testPos = Vector( math.Round(data.origin.x+data.x), math.Round(data.origin.y+data.y), math.Round(data.origin.z+data.z) )
	until !Unstuck.ToUnstuck[ply].CheckedPos[testPos]
	Unstuck.ToUnstuck[ply].CheckedPos[testPos] = true
	
	if util.IsInWorld( testPos ) then 
	
		local startPos = testPos + Vector(0,0,(maxBound.z-minBound.z)*0.5)
		local endPos = testPos + Vector(0,0,(maxBound.z-minBound.z)*0.5)
		
		-- This will simply have the starting position for the trace on the side of a players hull.
		-- Doing so should allow the trace to not fail if the player is more than half into the wall.
		startPos.x = math.Clamp( startPos.x, data.origin.x-(0.1), data.origin.x+(0.1) )
		startPos.y = math.Clamp( startPos.y, data.origin.y-(0.1), data.origin.y+(0.1) )
		startPos.z = math.Clamp( startPos.z, data.origin.z-(0.1), data.origin.z+(0.1) )
		
		-- Center the start position within the hull
		startPos.z = startPos.z + ((maxBound.z-minBound.z)*0.5)
	
		-- Trace to the test position to ensure we don't start getting out of the map
		local tr = util.TraceLine({
			start = startPos,
			endpos = endPos,
			filter = filter,
			mask = MASK_PLAYERSOLID
		})
		
		if !tr.Hit then
		
			Unstuck.DebugEvent( 
				ply, 
				Unstuck.Enumeration.Debug.COMMAND_ADD, 
				Unstuck.Enumeration.Debug.NOUN_LINE, 
				startPos, 
				endPos, 
				Color( 255,0,0 ) 
			)
		
			if Unstuck.CollisionBoxClear( ply, testPos, minBound, maxBound ) then
				Unstuck.DebugEvent( 
					ply, 
					Unstuck.Enumeration.Debug.COMMAND_ADD, 
					Unstuck.Enumeration.Debug.NOUN_BOX, 
					testPos + minBound, 
					testPos + maxBound, 
					Color( 255,255,0 ) 
				)	
			
				ply:SetPos( testPos )
				ply:UnstuckMessage( Unstuck.Enumeration.Message.UNSTUCK )
				return Unstuck.Enumeration.PositionTesting.PASSED
			else
				--Add new layer to further test
				data.data = Unstuck.AddLayer( ply, testPos )
				
			end
		end	
	
	end
	
	-- return failed
	if 	data.x > range.x and
		data.y > range.y and 
		data.z > range.z then
			return Unstuck.Enumeration.PositionTesting.FAILED
	end
	
end
