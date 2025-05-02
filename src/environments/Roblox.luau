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

	Luau.lua_pushcfunction(
		sandbox.L,
		Wasm.cfn(function(L)
			Reflector.reflectUserdataInto(L, UserSettings())

			return 1
		end),
		Wasm.cstr("")
	)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("UserSettings"))

	Luau.lua_pushcfunction(
		sandbox.L,
		Wasm.cfn(function(L)
			Reflector.reflectUserdataInto(L, settings())

			return 1
		end),
		Wasm.cstr("")
	)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("settings"))

	Reflector.reflectUserdataInto(sandbox.L, script)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("script"))

	Reflector.reflectUserdataInto(sandbox.L, game)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("game"))

	Reflector.reflectUserdataInto(sandbox.L, workspace)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("workspace"))

	sandbox:LoadBlob("roblox_task")
	sandbox:LoadBlob("roblox_env")

	sandbox:AddToScheduler(function()
		Scheduler.schedule(sandbox.L)
	end)
end
