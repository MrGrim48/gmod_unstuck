--[[
sv_unstuck_table.lua

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
	
	Unstuck.DebugEvent( 
		ply, 
		Unstuck.Enumeration.Debug.COMMAND_ADD, 
		Unstuck.Enumeration.Debug.NOUN_BOX, 
		ply:GetPos()+minBound, 
		ply:GetPos()+maxBound, 
		Color(255,150,150) 
	)
	
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
