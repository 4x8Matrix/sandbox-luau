--[[
	Reflector: A module which attempts to dynamically pull/push things to/from the VM, for example:
		You can reflect a string into the VM, which in turn implements your string in the wasm VM.
		You can reflect a string outside of the VM, so if there's something you want - you can get that.

	Supports all datatypes bar threads.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

local USERDATA_METATABLE = Wasm.cstr("UserdatMetatable")
local USERDATA_TAG = 1

local Reflector = {}

-- uuid value which will increment per new userdata
local userdataId = 0

-- map of unique userdata ids to userdata objects
local userdataIdMap: { [number]: any } = {}

-- map of userdata pointers to userdata ids
local userdataPointers: { [number]: number } = {}

--[[
	will fetch `USERDATA_METATABLE`, and then clone it - we're cloning the metatable in this case
	because we're later modifying entries in this metatable.

	So we need a shallow clone of this MT.
]]
function Reflector.cloneUserdataMetatable(L: Luau.LuaState): ()
	Luau.lua_newtable(L) -- +1: table
	Luau.luaL_getmetatable(L, USERDATA_METATABLE) -- +1: metatable

	Luau.lua_pushnil(L) -- +1: nil
	while Luau.lua_next(L, -2) ~= 0 do -- +2: key, value
		Luau.lua_pushvalue(L, -2)
		Luau.lua_pushvalue(L, -2)
		Luau.lua_settable(L, -6)
		Luau.lua_pop(L, 1) -- -1: pop value
	end

	Luau.lua_pop(L, 1) -- -1: pop metatable
end

--[[
	Will take a userdata in the current environment, and then reflect it into the VM.

	Example:
	```luau
	-- this will load the `game` userdata from Roblox, into the VM.
	Reflector.reflectUserdataInto(L, game)
	```
]]
function Reflector.reflectUserdataInto(L: Luau.LuaState, userdata: any): ()
	local index = userdataId + 1

	local userdataPtr = Luau.lua_newuserdata(L, 32) -- +1: userdata
	Luau.lua_setuserdatatag(L, -1, USERDATA_TAG)

	Reflector.cloneUserdataMetatable(L)

	--[[
		We're adding `userdata-id` to the metatable of this userdata, because we're not able to actually
		set the block of memory that this userdata holds. (Wasm limits!)

		So instead, we add what data we would store in the memory, into the metatable!
	]]
	Luau.lua_pushnumber(L, index)
	Luau.lua_setfield(L, -2, Wasm.cstr("userdata-id"))

	Luau.lua_setmetatable(L, -2)

	userdataId = index

	userdataIdMap[index] = userdata
	userdataPointers[userdataPtr] = index
end

--[[
	Opposite of `reflectUserdataInto`, if you're wanting to get userdata from the VM, you can use this
	function.
]]
function Reflector.reflectUserdataFrom(L: Luau.LuaState, index: number): any
	if Luau.luaL_getmetafield(L, index, Wasm.cstr("userdata-id")) == 1 then
		local id = Luau.lua_tonumberx(L, -1)

		Luau.lua_pop(L, 1)

		return userdataIdMap[id]
	else
		return nil
	end
end

--[[
	Will reflect any datatype into the VMs memory. The value is then left on the top of the value stack.
]]
function Reflector.reflectInto(L: Luau.LuaState, object: any): ()
	local valueType = type(object)

	if valueType == "table" then
		Luau.lua_newtable(L)

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

--[[
	Opposite of reflectInto, will take a datatype out of the VMs memory and translate it to a luau value.
]]
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

function Reflector.init(L: Luau.LuaState)
	Luau.lua_setuserdatadtor(
		L,
		USERDATA_TAG,
		Wasm.cfn(function(_L, userdataPtr)
			local index = userdataPointers[userdataPtr]
			local _instance = userdataIdMap[index]

			userdataIdMap[index] = nil
			userdataPointers[userdataPtr] = nil

			return 0
		end)
	)

	if Luau.luaL_newmetatable(L, USERDATA_METATABLE) == 1 then
		for metamethod, callback in
			{
				__namecall = function(L)
					local realObject = Reflector.reflectUserdataFrom(L, 1)
					local methodName = Wasm.luastr(Luau.lua_namecallatom(L, 0))

					local arguments = {}

					for index = 2, Luau.lua_gettop(L) do
						table.insert(arguments, Reflector.reflectFrom(L, index))
					end

					local method = realObject[methodName]
					local response = table.pack(method(realObject, table.unpack(arguments)))
					local responseCount = table.maxn(response)

					if responseCount ~= 0 then
						for index = 1, responseCount do
							Reflector.reflectInto(L, response[index])
						end

						return responseCount
					else
						return 0
					end
				end,
				__index = function(L)
					local realObject = Reflector.reflectUserdataFrom(L, -2)
					local index = Wasm.luastr(Luau.lua_tostring(L, -1))

					Reflector.reflectInto(L, realObject[index])

					return 1
				end,
				__newindex = function(L)
					local realObject = Reflector.reflectUserdataFrom(L, -3)
					local index = Wasm.luastr(Luau.lua_tostring(L, -2))
					local value = Reflector.reflectFrom(L, -3)

					realObject[index] = value

					return 0
				end,
				__tostring = function(L)
					local realObject = Reflector.reflectUserdataFrom(L, -1)

					Luau.lua_pushstring(L, Wasm.cstr(realObject.Name))

					return 1
				end,
			} :: { [string]: (...any) -> number }
		do
			Luau.lua_pushcfunction(L, Wasm.cfn(callback), 0)
			Luau.lua_setfield(L, -2, Wasm.cstr(metamethod))
		end
	end

	Luau.lua_pop(L, 1)
end

return Reflector
