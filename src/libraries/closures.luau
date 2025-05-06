--[[
	Closures: implements a luau library for closure related functionality.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

--[[
	Enables developers to create `c closures` from luau functions, mostly used to trick code into believing
	something was written from C
]]
local function cClosure(L0)
	Luau.lua_pushcclosure(
		L0,
		Wasm.cfn(function(L1)
			local numArgs = Luau.lua_gettop(L1)

			Luau.lua_pushvalue(L1, Luau.lua_upvalueindex(1))

			for i = 1, numArgs do
				Luau.lua_pushvalue(L1, i)
			end

			Luau.lua_pcall(L1, numArgs, -1, 0)

			local total = Luau.lua_gettop(L1)
			local retCount = total - numArgs

			return retCount
		end),
		Wasm.cstr(""),
		1
	)

	return 1
end

--[[
	Will clone the function that is at the given positon on the stack
]]
local function cloneFunction(L)
	Luau.luaL_checktype(L, -1, Luau.LUA_TFUNCTION)

	Luau.lua_clonefunction(L, -1)

	return 1
end

return function(sandbox)
	Luau.lua_newtable(sandbox.L)

	for name, callback in
		{
			cClosure = cClosure,
			cloneFunction = cloneFunction,
		} :: { [string]: any }
	do
		Luau.lua_pushcfunction(sandbox.L, Wasm.cfn(callback), Wasm.cstr(name))
		Luau.lua_setfield(sandbox.L, -2, Wasm.cstr(name))
	end

	Luau.lua_setglobal(sandbox.L, Wasm.cstr("closures"))
end
