--[[
	Runtime: an implementation of runtime specific functions, such as getting things from the registry, or gc.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

--[[
	Will return the registry for the current VM
]]
local function registry(L)
	Luau.lua_pushvalue(L, Luau.LUA_REGISTRYINDEX)

	return 1
end

return function(sandbox)
	Luau.lua_newtable(sandbox.L)

	for name, callback in
		{
			registry = registry,
		} :: { [string]: any }
	do
		Luau.lua_pushcfunction(sandbox.L, Wasm.cfn(callback), Wasm.cstr(name))
		Luau.lua_setfield(sandbox.L, -2, Wasm.cstr(name))
	end

	Luau.lua_setglobal(sandbox.L, Wasm.cstr("runtime"))
end
