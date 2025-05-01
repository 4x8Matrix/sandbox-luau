--[[
	Responsible for implementing a UNC Runtime environment.
]]

local Luau = require("../modules/Luau")

return function(sandbox)
	Luau.luaL_openlibs(sandbox.L)

	sandbox:LoadEnvironment("Roblox")
end
