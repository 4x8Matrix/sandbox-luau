--[[
	Responsible for implementing the Roblox Runtime environment.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")
local Scheduler = require("../modules/Scheduler")
local Reflector = require("../modules/Reflector")

return function(sandbox)
	sandbox:LoadEnvironment("Luau")
	sandbox:LoadLibrary("async")
	sandbox:LoadLibrary("glob")
	sandbox:LoadLibrary("closures")

	Scheduler.init(sandbox.L)

	Reflector.reflectUserdataInto(sandbox.L, "userSettings")
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("userSettings"))

	Reflector.reflectUserdataInto(sandbox.L, "settings")
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("settings"))

	Reflector.reflectUserdataInto(sandbox.L, "script")
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("script"))

	Reflector.reflectUserdataInto(sandbox.L, "game")
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("game"))

	Reflector.reflectUserdataInto(sandbox.L, "workspace")
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("workspace"))

	sandbox:LoadBlob("pp")
	sandbox:LoadBlob("roblox/task")
	sandbox:LoadBlob("roblox/env")

	sandbox:AddToScheduler(function()
		Scheduler.schedule(sandbox.L)
	end)
end
