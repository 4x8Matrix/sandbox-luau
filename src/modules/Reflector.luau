--[[
	Reflector: A module which attempts to dynamically pull/push things to/from the VM, for example:
		You can reflect a string into the VM, which in turn implements your string in the wasm VM.
		You can reflect a string outside of the VM, so if there's something you want - you can get that.

	Supports all datatypes bar threads.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")
local Cache = require("../modules/Cache")
local Scheduler = require("../modules/Scheduler")

local resumeWithErrorHandling = require("../functions/resumeWithErrorHandling")

local FUNCTION_REFS = Wasm.cstr("FunctionRefs")
local USERDATA_METATABLE = Wasm.cstr("UserdataMetatable")
local USERDATA_TAG = 1

local Reflector = {}

-- uuid value which will increment per new userdata
local userdataId = 0

-- map of unique userdata ids to userdata objects
local userdataIdMap: { [number]: any } = {}

-- opposite of the above, maps userdatas to ids
local idUserdataMap: { [any]: number } = {}

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

	local newUserdataPtr, exists = Cache.pushUserdata(L, userdata) -- +1: userdata

	if exists then
		return
	end

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
	userdataPointers[newUserdataPtr] = index
	idUserdataMap[userdata] = newUserdataPtr
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

				for index = 1, argCount do
					table.insert(args, Reflector.reflectFrom(L, index))
				end

				Luau.lua_pushthread(L)
				local thread = Luau.lua_tothread(L, -1)
				Luau.lua_pop(L, 1)

				Scheduler.pushFront(coroutine.create(function()
					local response = table.pack(pcall(object, table.unpack(args)))
					local responseCount = table.maxn(response) - 1

					if response[1] then
						for index = 1, responseCount do
							Reflector.reflectInto(thread, response[index + 1])
						end

						resumeWithErrorHandling(thread, L, responseCount)
					else
						print(`Runtime Error: {response[2]}`)
					end
				end))

				return Luau.lua_yield(L, 0)
			end),
			Wasm.cstr(debug.info(object, "s"))
		)
	elseif valueType == "userdata" or valueType == "vector" then
		Reflector.reflectUserdataInto(L, object)
	elseif valueType == "thread" then
		error("Can't reflect threads!")
	end
end

--[[
	Opposite of reflectInto, will take a datatype out of the VMs memory and translate it to a luau value.
]]
function Reflector.reflectFrom(L: Luau.LuaState, index: number): any
	local valueType = Wasm.luastr(Luau.luaL_typename(L, index))

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
		-- fixme: we don't ever remove this from ref..
		Luau.lua_pushvalue(L, index)
		local ref = Luau.lua_ref(L, -1)
		Luau.lua_pop(L, 1)

		return function(...)
			local thread = Luau.lua_newthread(L)
			local argCount = select("#", ...)

			Luau.lua_rawgeti(thread, Luau.LUA_REGISTRYINDEX, ref)

			for i = 1, argCount do
				Reflector.reflectInto(thread, select(i, ...))
			end

			resumeWithErrorHandling(thread, L, argCount)
		end
	elseif valueType == "userdata" or valueType == "vector" then
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
			local userdata = userdataIdMap[index]

			userdataIdMap[index] = nil
			userdataPointers[userdataPtr] = nil
			idUserdataMap[userdata] = nil

			Cache.removeUserdata(L, userdata)

			return 0
		end)
	)

	Luau.lua_newtable(L)
	Luau.lua_setfield(L, Luau.LUA_REGISTRYINDEX, FUNCTION_REFS)

	if Luau.luaL_newmetatable(L, USERDATA_METATABLE) == 1 then
		for metamethod, object in
			{
				__metatable = "The metatable is locked",
				__namecall = function(L)
					local instance = Reflector.reflectUserdataFrom(L, 1)
					local methodName = Wasm.luastr(Luau.lua_namecallatom(L, 0))

					local arguments = {}

					for index = 2, Luau.lua_gettop(L) do
						table.insert(arguments, Reflector.reflectFrom(L, index))
					end

					Luau.lua_pushthread(L)
					local thread = Luau.lua_tothread(L, -1)
					Luau.lua_pop(L, 1)

					Scheduler.pushBack(coroutine.create(function()
						local method = instance[methodName]
						local response = table.pack(method(instance, table.unpack(arguments)))
						local responseCount = table.maxn(response)

						for index = 1, responseCount do
							Reflector.reflectInto(thread, response[index])
						end

						resumeWithErrorHandling(thread, L, responseCount)
					end))

					return Luau.lua_yield(L, 0)
				end,
				__index = function(L)
					local instance = Reflector.reflectUserdataFrom(L, -2)
					local index = Wasm.luastr(Luau.lua_tostring(L, -1))

					Reflector.reflectInto(L, instance[index])

					return 1
				end,
				__newindex = function(L)
					local instance = Reflector.reflectUserdataFrom(L, -3)
					local index = Wasm.luastr(Luau.lua_tostring(L, -2))
					local value = Reflector.reflectFrom(L, -1)

					instance[index] = value

					return 0
				end,
				__call = function(L)
					local instance = Reflector.reflectUserdataFrom(L, 1)

					local arguments = {}

					for index = 2, Luau.lua_gettop(L) do
						table.insert(arguments, Reflector.reflectFrom(L, index))
					end

					local response = table.pack(instance(table.unpack(arguments)))
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
				__tostring = function(L)
					local instance = Reflector.reflectUserdataFrom(L, 1)

					Reflector.reflectInto(L, tostring(instance))

					return 1
				end,
			} :: { [string]: any }
		do
			local objectType = type(object)

			if objectType == "function" then
				Luau.lua_pushcfunction(L, Wasm.cfn(object), 0)
			elseif objectType == "string" then
				Luau.lua_pushstring(L, Wasm.cstr(object))
			else
				error(`Unknown type: {objectType}`)
			end

			Luau.lua_setfield(L, -2, Wasm.cstr(metamethod))
		end
	end

	Luau.lua_pop(L, 1)
end

return Reflector
