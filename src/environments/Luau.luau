--[[
	Responsible for implementing the standard Luau environment.
]]

local Luau = require("../modules/Luau")

return function(sandbox)
	Luau.luaL_openlibs(sandbox.L)
end
