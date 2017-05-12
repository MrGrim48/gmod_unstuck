--[[
sv_unstuck_table.lua

Copyright© Nekom Glew, 2017

--]]

Unstuck.ToUnstuck = {}

--[[------------------------------------------------
	Name: Queue()
	Desc: Queue a player to be unstuck.
--]]------------------------------------------------
function Unstuck.Queue( ply )
	
	-- Return if the player is already in the queue
	if Unstuck.ToUnstuck[ply] then return end
	
	local minBound, maxBound = ply:GetHull()
	maxBound.z = maxBound.z - minBound.z
	minBound.z = 0
	
	net.Start( "Unstuck.Debug" )
	net.WriteString( "add" )
	net.WriteString( "box" )
	net.WriteVector( ply:GetPos()+minBound )
	net.WriteVector( ply:GetPos()+maxBound )
	net.WriteColor( Color(255,150,150) )
	net.Send( ply )
	
	Unstuck.ToUnstuck[ply] = Unstuck.AddLayer( ply, ply:GetPos() )
	Unstuck.ToUnstuck[ply].data = Unstuck.AddLayer( ply, ply:GetPos() )
	Unstuck.ToUnstuck[ply].CheckedPos = {}
	return true
	
end

--[[------------------------------------------------
	Name: AddLayer()
	Desc: This will create and return a table 
--]]------------------------------------------------
function Unstuck.AddLayer( ply, pos )

	local minBound, maxBound = ply:GetHull()

	local layer = {}
	layer.origin = pos
	layer.data = nil
	layer.x = 0
	layer.y = 0
	layer.z = 0
	
	return layer

end