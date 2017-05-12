--[[
sv_unstuck.lua

Copyright© Nekom Glew, 2017

--]]

--[[------------------------------------------------
	Name: CollisionBoxClear()
	Desc: Returns true if the players Bounding Box fits at the given position.
--]]------------------------------------------------
function Unstuck.CollisionBoxClear( ply, pos, minBound, maxBound )

	maxBound.z = maxBound.z - minBound.z
	minBound.z = 0
	
	local filter = {ply}
	if ply.ph_prop then table.insert( filter, ply.ph_prop ) end
	
	local tr = util.TraceHull({
		start = pos,
		endpos = pos,
		maxs = maxBound,
		mins = minBound,
		filter = filter,
		mask = MASK_ALL
	})
	
	net.Start( "Unstuck.Debug" )
	net.WriteString( "add" )
	net.WriteString( "box" )
	net.WriteVector( pos + minBound )
	net.WriteVector( pos + maxBound )
	net.WriteColor( Color(255,255,255) )
	net.Send( ply )
	
	return !tr.StartSolid || !tr.AllSolid
	
end

--[[------------------------------------------------
	Name: Unstuck.Start()
	Desc: Attempts to start the unstuck process.
		Will not attempt if the player is in a vehicle, dead or not stuck in the first place.
--]]------------------------------------------------
function Unstuck.Start( ply )

	-- Fail if the player is in a vehicle, dead or spectating
	if ply:GetMoveType() == MOVETYPE_OBSERVER || ply:InVehicle() || !ply:Alive() then
		ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "You must be alive and out of vehicles to use this command!" )
		return
	end
	
	--[[---------Optional Code--------]]--
	-- This code is for my custom verion of Prop Hunt and can be removed
	if ply:Team() == TEAM_PROPS && ply:GetNWBool( "PhysicsMode" ) then
		ply:SetNWBool( "PhysicsMode", false )
		Props.PhysicsMode.SetPhysicsMode( ply, false )
	end
	--------------------------------------
	
	-- Clears the current debug lines
	net.Start( "Unstuck.Debug" )
	net.WriteString( "new" )
	net.Send( ply )
	
	local minBound, maxBound = ply:GetHull()
	if !Unstuck.CollisionBoxClear( ply, ply:GetPos(), minBound, maxBound ) then
		local isNotQueued = Unstuck.Queue( ply ) -- Adds to the unstuck queue
		if isNotQueued then
			ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "You are stuck, trying to free you..." )
		end
	else
		ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "You should be unstuck!" )
	end

-- Alert staff of any attempts
	for k,v in pairs( player.GetAll() ) do
		if (v:CheckGroup( "moderator" ) || v:IsAdmin() || v:IsSuperAdmin()) && v != ply then
			v:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,0,0), ply:Nick(), Color(255,255,255), " used the Unstuck command." )
		end
	end
	
end

--[[------------------------------------------------
	Name: PlayerSay()
	Desc: Runs Unstuck.Start if the chat command is given and possible.
--]]------------------------------------------------
hook.Add("PlayerSay", "Unstuck.PlayerSay", function( ply, text )
	
	text = string.lower( text )
	if ( text == "!unstuck" or text == "!stuck" or text == "/stuck" or text == "/unstuck" ) then
		
		if DarkRP then				
			if (ply.isArrested && ply:isArrested()) || (ply.IsArrested && ply:IsArrested()) then
				ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "You are arrested!" )
				return ""
			end
		end
		
		if (ply.UnstuckCooldown || 0) < CurTime() then
			ply.UnstuckCooldown = CurTime() + Unstuck.Cooldown
			Unstuck.Start( ply )
		else
			ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "Cooldown period still active! Wait a bit!" )
		end
		
		return ""
	end
	
end )