local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[
	Responsible for implementing a UNC Runtime environment.
]]

local Cache = require(ReplicatedStorage.Packages.SandboxLuau.modules.Cache)
local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")
local Reflector = require("../modules/Reflector")

return function(sandbox)
	sandbox:LoadEnvironment("Roblox")
	sandbox:LoadLibrary("unc_cache")

	Luau.lua_pushcfunction(
		sandbox.L,
		Wasm.cfn(function(L)
			local object = Reflector.reflectUserdataFrom(L, -1)

			Cache.removeUserdata(L, object)
			Reflector.reflectUserdataInto(L, object)

			return 1
		end),
		Wasm.cstr("")
	)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("cloneref"))

	Luau.lua_pushcfunction(
		sandbox.L,
		Wasm.cfn(function(L)
			local object = Reflector.reflectUserdataFrom(L, -1)
			local targetObject = Reflector.reflectUserdataFrom(L, -2)

			Luau.lua_pushboolean(L, object == targetObject and 1 or 0)

			return 1
		end),
		Wasm.cstr("")
	)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("compareinstances"))

	Luau.lua_pushcfunction(
		sandbox.L,
		Wasm.cfn(function(L)
			Luau.lua_pushboolean(L, 1)

			return 1
		end),
		Wasm.cstr("")
	)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("checkcaller"))

	Luau.lua_pushcfunction(
		sandbox.L,
		Wasm.cfn(function(L)
			Reflector.reflectInto(L, script)

			return 1
		end),
		Wasm.cstr("")
	)
	Luau.lua_setglobal(sandbox.L, Wasm.cstr("getcallingscript"))

	sandbox:LoadBlob("unc_env")
end
