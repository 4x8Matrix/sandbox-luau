--[[
	
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")
local Reflector = require("../modules/Reflector")
local Cache = require("../modules/Cache")

local function invalidate(L)
	local object = Reflector.reflectUserdataFrom(L, -1)

	Cache.removeUserdata(L, object)

	return 0
end

local function iscached(L)
	local object = Reflector.reflectUserdataFrom(L, -1)

	Luau.lua_pushboolean(L, Cache.userdataInCache(L, object) == true and 1 or 0)

	return 1
end

local function replace(L)
	local object0 = Reflector.reflectUserdataFrom(L, -1)
	local object1 = Reflector.reflectUserdataFrom(L, -2)

	Cache.replaceUserdata(L, object0, object1)

	return 0
end

return function(sandbox)
	Luau.lua_newtable(sandbox.L)

	for name, callback in
		{
			invalidate = invalidate,
			iscached = iscached,
			replace = replace,
		} :: { [string]: any }
	do
		Luau.lua_pushcfunction(sandbox.L, Wasm.cfn(callback), Wasm.cstr(name))
		Luau.lua_setfield(sandbox.L, -2, Wasm.cstr(name))
	end

	Luau.lua_setglobal(sandbox.L, Wasm.cstr("cache"))
end
