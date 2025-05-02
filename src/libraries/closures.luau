--[[
	
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

--[[
	
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

return function(sandbox)
	Luau.lua_newtable(sandbox.L)

	for name, callback in
		{
			cClosure = cClosure,
		} :: { [string]: any }
	do
		Luau.lua_pushcfunction(sandbox.L, Wasm.cfn(callback), Wasm.cstr(name))
		Luau.lua_setfield(sandbox.L, -2, Wasm.cstr(name))
	end

	Luau.lua_setglobal(sandbox.L, Wasm.cstr("closures"))
end
