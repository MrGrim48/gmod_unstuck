
if SERVER then
	AddCSLuaFile()
	AddCSLuaFile "unstuck/sh_unstuck.lua"
	AddCSLuaFile "unstuck/cl_unstuck.lua"
	
	include "unstuck/sh_unstuck.lua"
	include "unstuck/sv_unstuck.lua"
	include "unstuck/sv_unstuck_table.lua"
	include "unstuck/sv_unstuck_func.lua"
else
	include "unstuck/sh_unstuck.lua"
	include "unstuck/cl_unstuck.lua"
end