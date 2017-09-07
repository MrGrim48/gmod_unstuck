--[[
sh_unstuck.lua

Main file for configuration and message handling.

--]]

Unstuck = {}

--[[---------------------------
		CONFIGURATION
--]]---------------------------
Unstuck.Configuration = {

	// The chat command for players to use.
	Command = {
		Prefix = { "!", "/" },
		String = { "stuck", "unstuck" },
	},
	
	// Admins will be notified when a player attemps to use the Unstuck function.
	AdminRanks = {
		"moderator",
		"admin",
		"superadmin",
		"owner",
	},
	
	// Allow the debug information to be sent only to the ranked admins.
	DebugAdminRanksOnly = true, 
	
	// If the unstuck fails, the player will be be respawned.
	RespawnOnFail = true,
	// The time in seconds between the failed message and respawning the player. 
	RespawnTimer = 3,
	
	// Cooldown between each unstuck attempt in seconds.
	Cooldown = 5,
	
	// MaxDepth is related to the line of sight. Initially it's a line of sight 
	// from the player to the new position. Incrementing until the max depth, it will
	// chain the line of sight from the last possible position.
	// Beter description needed. Will wait until after changes made to the algorithm.
	MaxDepth = 3, 
}


--[[---------------------------
		ENUMERATION
--]]---------------------------
Unstuck.Enumeration = {

	Message = {
		UNSTUCK = 1,
		UNSTUCK_ATTEMPT = 2,
		ADMIN_NOTIFY = 3,
		NOT_ALIVE = 4,
		ARRESTED = 5,
		COOLDOWN = 6,
		FAILED = 7,
		RESPAWNING = 8,
		RESPAWN_FAILED = 9,
	},
	
	PositionTesting = {
		PASSED = 1,
		FAILED = 2,
	},
	
	Debug = {
		COMMAND_ADD = 1,
		COMMAND_CLEAR = 2,
		NOUN_BOX = 3,
		NOUN_LINE = 4
	}
}


--[[---------------------------
		DICTIONARY FOR MESSAGES
--]]---------------------------
Unstuck.Dictionary = {
	[Unstuck.Enumeration.Message.UNSTUCK] = "You should be unstuck!",
	[Unstuck.Enumeration.Message.UNSTUCK_ATTEMPT] = "You are stuck, trying to free you...",
	[Unstuck.Enumeration.Message.ADMIN_NOTIFY] = " used the Unstuck command.", // The players name will be prefixed with this string
	[Unstuck.Enumeration.Message.NOT_ALIVE] = "You must be alive and out of vehicles to use this command!",
	[Unstuck.Enumeration.Message.ARRESTED] = "You are arrested!",
	[Unstuck.Enumeration.Message.COOLDOWN] = "Cooldown period still active! Wait a bit!",
	[Unstuck.Enumeration.Message.FAILED] = "Sorry, I failed.",
	[Unstuck.Enumeration.Message.RESPAWNING] = "Respawning in "..Unstuck.Configuration.RespawnTimer.." seconds.",
	[Unstuck.Enumeration.Message.RESPAWN_FAILED] = "Respawn canceled. Your are dead.",
}


--[[---------------------------
		Message handling below.
--]]---------------------------
if SERVER then
	
	util.AddNetworkString( "Unstuck.Message" )
	util.AddNetworkString( "Unstuck.Debug" )
	local Player = FindMetaTable( "Player" )

	
	--[[------------------------------------------------
		Name: PlayerMessage()
		Desc: Sends a message to a single player.
			2nd argument used with Admin Notify
	--]]------------------------------------------------
	function Player:UnstuckMessage( enumMessage, ply )
		net.Start( "Unstuck.Message" )
		net.WriteInt( enumMessage, 8 )
		
		-- Also send the target player if notifying admins.
		if ( enumMessage == Unstuck.Enumeration.Message.ADMIN_NOTIFY ) then
			net.WriteEntity( ply )
		end
		
		net.Send( self )
	end
 
end

if CLIENT then
		
	net.Receive( "Unstuck.Message", function()
		local enumMessage = net.ReadInt( 8 )
		local message = {Color(255,255,0), "[Unstuck] "}
		
		if enumMessage == Unstuck.Enumeration.Message.ADMIN_NOTIFY then
			local ply = net.ReadEntity()
			table.Add( message, {Color(255,0,0), ply:Nick()} )
		end
		
		table.insert( message, Color(255,255,255) )
		chat.AddText( unpack( message ) )
	end)

end
