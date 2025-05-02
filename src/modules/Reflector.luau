--[[
	Welcome to the Reflector! This module is primarily responsible for the asynchronous execution of threads.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

local Reflector = {}

function Reflector.reflectUserdataInto(L: Luau.LuaState, userdata: any): ()
	Luau.lua_pushlightuserdata(L, 8)
end

function Reflector.reflectUserdataFrom(L: Luau.LuaState, userdata: any): () end

function Reflector.reflectInto(L: Luau.LuaState, object: any): ()
	local valueType = type(object)

	if valueType == "table" then
		Luau.lua_createtable(L)

		for key, value in object do
			Reflector.reflectInto(L, key)
			Reflector.reflectInto(L, value)
			Luau.lua_settable(L, -3)
		end
	elseif valueType == "string" then
		Luau.lua_pushstring(L, Wasm.cstr(object))
	elseif valueType == "number" then
		Luau.lua_pushinteger(L, object)
	elseif valueType == "boolean" then
		Luau.lua_pushboolean(L, object)
	elseif valueType == "nil" then
		Luau.lua_pushnil(L)
	elseif valueType == "function" then
		Luau.lua_pushcfunction(
			L,
			Wasm.cfn(function(L)
				local argCount = Luau.lua_gettop(L)
				local args = {}

				for _ = 1, argCount do
					table.insert(args, Reflector.reflectFrom(L, 1))
				end

				local results = { pcall(object, table.unpack(args)) }

				if results[1] then
					for i = 2, #results do
						Reflector.reflectInto(L, results[i])
					end

					return #results - 1
				else
					Luau.lua_pushstring(L, Wasm.cstr(`Error: {results[2]}`))
					Luau.lua_error(L)

					return 1
				end
			end),
			debug.info(object, "s")
		)
	elseif valueType == "userdata" then
		Reflector.reflectUserdataInto(L, object)
	elseif valueType == "thread" then
		error("Can't reflect threads!")
	end
end

function Reflector.reflectFrom(L: Luau.LuaState, index: number): any
	local valueType = Luau.lua_type(L, index)

	if valueType == "table" then
		local table = {}

		Luau.lua_pushnil(L) -- +1: nil
		while Luau.lua_next(L, index) ~= 0 do -- +2: key, value
			local key = Reflector.reflectFrom(L, -2)
			local value = Reflector.reflectFrom(L, -1)
			table[key] = value
			Luau.lua_pop(L, 1) -- -1: pop value
		end

		return table
	elseif valueType == "string" then
		return Wasm.luastr(Luau.lua_tostring(L, index))
	elseif valueType == "number" then
		return Luau.lua_tonumberx(L, index)
	elseif valueType == "boolean" then
		return Luau.lua_toboolean(L, index) == 1
	elseif valueType == "nil" then
		return nil
	elseif valueType == "function" then
		return function()
			error(`Unable to reflect luau function! (doing this could waste a lot of the VMs memory)`)
		end
	elseif valueType == "userdata" then
		return Reflector.reflectUserdataFrom(L, index)
	elseif valueType == "thread" then
		error("Can't reflect threads!")
	end

	return nil
end

return Reflector
