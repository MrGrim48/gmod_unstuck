--[[
sv_unstuck_func.lua

Copyright© Nekom Glew, 2017

--]]


local function SpawnPlayer( ply )
	if IsValid(ply) then
		if ply:Alive() then
			ply:Spawn()
		else
			ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "Respawn canceled. Your are dead." )
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
	if data.data and depth < Unstuck.MaxDepth then --If Another layer exists and less than max depth
		if LoopData( ply, data.data, depth+1 ) then
			data.data = nil
		end
	else
		local result = Unstuck.FindNewPos( ply, data )
		if result == "passed" then
			Unstuck.ToUnstuck[ply] = nil
		elseif result == "end" then
			return true
		end
	
		if Unstuck.ToUnstuck[ply] and !Unstuck.ToUnstuck[ply].data then
			Unstuck.ToUnstuck[ply] = nil
			ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "Sorry, I failed." )
			
			if Unstuck.RespawnOnFail then
				if Unstuck.RespawnTimer > 0 then
					ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "Respawning in "..Unstuck.RespawnTimer.." seconds." )
					timer.Simple( Unstuck.RespawnTimer, function()
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
		Returns "passed" if there is a viable postion.
		Returns "end" if no nearby positions available.
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
	
		-- Trace to the test position to ensure we don't start getting out of the map
		local tr = util.TraceLine({
			start = startPos,
			endpos = endPos,
			filter = filter,
			mask = MASK_ALL
		})
		
		if !tr.Hit then
		
			net.Start( "Unstuck.Debug" )
			net.WriteString( "add" )
			net.WriteString( "line" )
			net.WriteVector( startPos )
			net.WriteVector( endPos )
			net.WriteColor( Color( 255,0,0 ) )
			net.Send( ply )
		
			if Unstuck.CollisionBoxClear( ply, testPos, minBound, maxBound ) then
				net.Start( "Unstuck.Debug" )
				net.WriteString( "add" )
				net.WriteString( "box" )
				net.WriteVector( testPos + minBound )
				net.WriteVector( testPos + maxBound )
				net.WriteColor( Color( 255,255,0 ) )
				net.Send( ply )
			
				ply:SetPos( testPos )
				ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "You should be unstuck!" )
				return "passed"
			else
				--Add new layer to further test
				data.data = Unstuck.AddLayer( ply, testPos )
				
			end
		end	
	
	end
	
	-- return end
	if 	data.x > range.x and
		data.y > range.y and 
		data.z > range.z then
			return "end"
	end
	
end