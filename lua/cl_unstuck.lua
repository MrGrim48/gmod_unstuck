--[[
cl_unstuck_table.lua

Copyright© Nekom Glew, 2017

This is kinda messy and just quickly put together.

--]]

-- Convar to display the unstuck results.
CreateClientConVar( "unstuck_debug", "0" )

--[[------------------------------------------------
	Name: Unstuck.Debug()
	Desc: Stores the information in a table for the unstuck results.
--]]------------------------------------------------
net.Receive( "Unstuck.Debug", function( len, ply )
	local task = net.ReadString()
	if task == "new" then
		LocalPlayer().Unstuck = {}
	elseif task == "add" then
		LocalPlayer().Unstuck = LocalPlayer().Unstuck or {}
		local displayType = net.ReadString()
		local point1 = net.ReadVector()
		local point2 = net.ReadVector()
		local color = net.ReadColor()
		table.insert(LocalPlayer().Unstuck, {
			type = displayType,
			point1 = point1,
			point2 = point2,
			color = color
		} )
	end
end )

--[[------------------------------------------------
	Name: PostDrawOpaqueRenderables()
	Desc: Draws Lines or WireFrame Boxes of the unstuck results that have been stored.
--]]------------------------------------------------
hook.Add( "PostDrawOpaqueRenderables", "Unstuck.Debug.Draw", function( drawDepth, drawSkybox )

	if GetConVar("unstuck_debug"):GetInt() == 1 then
		if LocalPlayer().Unstuck then
			for _, data in pairs( LocalPlayer().Unstuck ) do
				if data.type == "box" then 
					render.DrawWireframeBox( Vector(), Angle(), data.point1, data.point2, data.color, true )
				elseif data.type == "line" then
					render.DrawLine( data.point1, data.point2, data.color, true )
				end
			end
		end
		
		local minBound, maxBound = LocalPlayer():GetHull()
		render.DrawWireframeBox( LocalPlayer():GetPos()+Vector(0,0,minBound.z), Angle(), minBound, maxBound, Color(255,0,255), true )
		
		cam.Start3D2D( LocalPlayer():GetPos()+Vector(0,-10,5), Angle(0, 0, 0), 0.3 )
			draw.DrawText(LocalPlayer():GetPos())
		cam.End3D2D()
	end
		
end )