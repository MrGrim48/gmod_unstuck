--[[
sh_unstuck.lua

A player can type !stuck or !unstuck; In doing so, this script
will attempt to move the player to a vacant area based on the players
hull and if the new position is within line of sight of the stuck player to
prevent them from teleporting through walls.

I've done what I can to make this unstuck as least exploitable as I possibly can.

--]]

Unstuck = {}
Unstuck.RespawnOnFail = true -- If the unstuck fails, the player will be be respawned.
Unstuck.RespawnTimer = 3 -- The time in seconds between the failed message and respawning the player. 
Unstuck.Cooldown = 5 -- Cooldown between each unstuck attempt in seconds.
Unstuck.MaxDepth = 3 -- MaxDepth is related to the line of sight. Initially it's a line of sight 
	-- from the player to the new position. Incrementing until the max depth, it will
	-- chain the line of sight from the last possible position.
	-- Think snake.
Unstuck.AdminRanks = {
	"moderator",
	"admin",
	"superadmin",
	"owner",
}

if SERVER then
	
	util.AddNetworkString( "Unstuck.Message" )
	util.AddNetworkString( "Unstuck.Debug" )
	local Player = FindMetaTable( "Player" )

	
	--[[------------------------------------------------
		Name: PlayerMessage()
		Desc: Sends a message to a single player.
	--]]------------------------------------------------
	function Player:UnstuckMessage( ... )
		local args = {...}
		net.Start( "Unstuck.Message" )
		net.WriteTable( args )
		net.Send( self )
	end
 
end

if CLIENT then
		
	net.Receive( "Unstuck.Message", function( len ) 
		local msg = net.ReadTable()
		chat.AddText( unpack( msg ) )
	end)

end
