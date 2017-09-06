--[[
sv_unstuck.lua

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
	
	local tr = util.TraceEntity({
		start = pos,
		endpos = pos,
		filter = filter,
		mask = MASK_PLAYERSOLID
	}, ply)
	
	Unstuck.DebugEvent( 
		ply, 
		Unstuck.Enumeration.Debug.COMMAND_ADD, 
		Unstuck.Enumeration.Debug.NOUN_BOX, 
		pos + minBound, 
		pos + maxBound, 
		Color(255,255,255) 
	)
	
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
	
	-- Clears the current debug lines
	Unstuck.DebugEvent( ply, Unstuck.Enumeration.Debug.COMMAND_CLEAR )
	
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
		if ( table.HasValue( Unstuck.Configuration.AdminRanks, v:GetUserGroup() ) || v:IsAdmin() || v:IsSuperAdmin() ) && v != ply then
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
	
	-- Check for command prefix.
	if not table.HasValue( 
		Unstuck.Configuration.Command.Prefix,
		text:sub( 1, 1 )
	) then return end
	
	-- Check for command string.
	if not table.HasValue(
		Unstuck.Configuration.Command.String,
		text:sub( 2, #text )
	) then return end
	
	
	if DarkRP then				
		if (ply.isArrested && ply:isArrested()) || (ply.IsArrested && ply:IsArrested()) then
			ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "You are arrested!" )
			return ""
		end
	end
	
	
	if ( ply.UnstuckCooldown || 0 ) < CurTime() then
		ply.UnstuckCooldown = CurTime() + Unstuck.Configuration.Cooldown
		Unstuck.Start( ply )
	else
		ply:UnstuckMessage( Color(255,255,0), "[Unstuck] ", Color(255,255,255), "Cooldown period still active! Wait a bit!" )
	end
	
	return ""
	
end )

--[[------------------------------------------------
	Name: Unstuck.DebugEvent()
	Desc: Primarily to remove duplicated Convar and admin rank checks
--]]------------------------------------------------
function Unstuck.DebugEvent( ply, command, noun, vec1, vec2, color )
	
	-- If only available to Admins. Return if player is not an admin
	if Unstuck.Configuration.DebugAdminRanksOnly and
	not table.HasValue( Unstuck.Configuration.AdminRanks, ply:GetUserGroup() ) then
		return
	end
	
	-- Return if ConVar is "0"
	if ply:GetInfo( "unstuck_debug" ) == "0" then return end
	

	net.Start( "Unstuck.Debug" )
	net.WriteInt( command, 8 )
	
	-- Because we know COMMAND_CLEAR does not need any other arguments
	if command == Unstuck.Enumeration.Debug.COMMAND_CLEAR then 
		net.Send( ply )
		return 
	end
	
	net.WriteInt( noun, 8 )
	net.WriteVector( vec1 )
	net.WriteVector( vec2 )
	net.WriteColor( color )
	net.Send( ply )
end