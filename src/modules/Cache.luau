local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Wasm = require(ReplicatedStorage.Packages.SandboxLuau.modules.Wasm)
local Luau = require("../modules/Luau")

local CACHE_KEY = Luau.malloc(8)

local pointerMap = {}

local Cache = {}

--[[
    Will either construct a new userdatum, or re-use existing userdatum.
]]
function Cache.pushUserdata(L, object)
	local exists = pointerMap[object] ~= nil
	local pointer = pointerMap[object]

	if pointer then
		Luau.lua_pushlightuserdata(L, CACHE_KEY)
		Luau.lua_rawget(L, Luau.LUA_REGISTRYINDEX)
		Luau.lua_pushnumber(L, pointer)
		Luau.lua_rawget(L, -2)
		Luau.lua_remove(L, -2)
	else
		pointer = Luau.lua_newuserdata(L, 32)
		pointerMap[object] = pointer

		Luau.lua_pushlightuserdata(L, CACHE_KEY)
		Luau.lua_rawget(L, Luau.LUA_REGISTRYINDEX)

		Luau.lua_pushnumber(L, pointer)
		Luau.lua_pushvalue(L, -3)
		Luau.lua_rawset(L, -3)
		Luau.lua_pop(L, 1)
	end

	return pointer, exists
end

function Cache.removeUserdata(_: Luau.LuaState, object)
	pointerMap[object] = nil
end

function Cache.userdataInCache(_: Luau.LuaState, object)
	return pointerMap[object] ~= nil
end

function Cache.replaceUserdata(_: Luau.LuaState, object0, object1)
	pointerMap[object0] = pointerMap[object1]
end

function Cache.init(L: Luau.LuaState)
	Luau.lua_newtable(L)
	Luau.lua_newtable(L)
	Luau.lua_pushstring(L, Wasm.cstr("v"))
	Luau.lua_setfield(L, -2, Wasm.cstr("__mode"))
	Luau.lua_setmetatable(L, -2)

	Luau.lua_pushlightuserdata(L, CACHE_KEY)
	Luau.lua_pushvalue(L, -2)
	Luau.lua_rawset(L, Luau.LUA_REGISTRYINDEX)
	Luau.lua_pop(L, 1)
end

return Cache
