--[[
	Glob: implements a library for messing around with the runtimes global things, for instance:
		- Allows mutation of the environment
		- Allows setting global variables
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

--[[
	Will globally set a variable
]]
local function set(L)
	local value = Luau.luaL_checkstring(L, -2)

	Luau.lua_pushvalue(L, -1)
	Luau.lua_setglobal(L, value)

	return 0
end

--[[
	Will set the environment of any future evaluations.
]]
local function environment(L)
	Luau.luaL_checktype(L, -1, Luau.LUA_TTABLE)

	Luau.lua_pushvalue(L, -1)
	Luau.lua_setfield(L, Luau.LUA_REGISTRYINDEX, Wasm.cstr("__ENV"))

	return 0
end

return function(sandbox)
	Luau.lua_newtable(sandbox.L)

	for name, callback in
		{
			set = set,
			environment = environment,
		} :: { [string]: any }
	do
		Luau.lua_pushcfunction(sandbox.L, Wasm.cfn(callback), Wasm.cstr(name))
		Luau.lua_setfield(sandbox.L, -2, Wasm.cstr(name))
	end

	Luau.lua_setglobal(sandbox.L, Wasm.cstr("glob"))
end
