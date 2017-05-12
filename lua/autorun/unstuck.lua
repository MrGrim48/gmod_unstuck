
if SERVER then
	AddCSLuaFile()
	AddCSLuaFile "sh_unstuck.lua"
	AddCSLuaFile "cl_unstuck.lua"
	
	include "sh_unstuck.lua"
	include "sv_unstuck.lua"
	include "sv_unstuck_table.lua"
	include "sv_unstuck_func.lua"
else
	include "sh_unstuck.lua"
	include "cl_unstuck.lua"
end