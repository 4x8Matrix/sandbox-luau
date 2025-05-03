--[[
	Welcome to the Scheduler! This module is primarily responsible for the asynchronous execution of threads.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

local ACTIVE_THREAD_DEQUEUE = Wasm.cstr("ACTIVE_THREAD_DEQUEUE")
local INACTIVE_THREAD_DEQUEUE = Wasm.cstr("INACTIVE_THREAD_DEQUEUE")

local Scheduler = {}

--[[
	Enqueues a thread to be run at the front of the queue.
]]
function Scheduler.pushFront(L: Luau.LuaState, thread: Luau.LuaThread, argCount: number?): ()
	Luau.lua_getfield(L, Luau.LUA_REGISTRYINDEX, INACTIVE_THREAD_DEQUEUE) -- +1: dequeue

	Luau.lua_getfield(L, -1, Wasm.cstr("first"))
	local first = Luau.lua_tonumberx(L, -1)
	Luau.lua_pop(L, 1)

	Luau.lua_pushinteger(L, first - 1)
	Luau.lua_setfield(L, -2, Wasm.cstr("first"))

	Luau.lua_pushinteger(L, first - 1)
	Luau.lua_newtable(L)

	Luau.lua_pushthread(L, thread)
	Luau.lua_setfield(L, -2, Wasm.cstr("thread"))

	Luau.lua_newtable(L)
	for i = 1, argCount or 0 do
		Luau.lua_pushvalue(L, -(3 + i))
		Luau.lua_rawseti(L, -2, i)
	end
	Luau.lua_setfield(L, -2, Wasm.cstr("args"))

	Luau.lua_settable(L, -3)

	Luau.lua_pop(L, 1) -- pop dequeue
end

--[[
	Enqueues a thread to be run at the back of the queue.
]]
function Scheduler.pushBack(L: Luau.LuaState, thread: Luau.LuaThread, argCount: number?): ()
	Luau.lua_getfield(L, Luau.LUA_REGISTRYINDEX, INACTIVE_THREAD_DEQUEUE) -- +1: dequeue

	Luau.lua_getfield(L, -1, Wasm.cstr("last"))
	local last = Luau.lua_tonumberx(L, -1)
	Luau.lua_pop(L, 1)

	Luau.lua_pushinteger(L, last + 1)
	Luau.lua_setfield(L, -2, Wasm.cstr("last"))

	Luau.lua_pushinteger(L, last + 1)
	Luau.lua_newtable(L)

	Luau.lua_pushthread(L, thread)
	Luau.lua_setfield(L, -2, Wasm.cstr("thread"))

	Luau.lua_newtable(L)
	for i = 1, argCount or 0 do
		Luau.lua_pushvalue(L, -(3 + i))
		Luau.lua_rawseti(L, -2, i)
	end
	Luau.lua_setfield(L, -2, Wasm.cstr("args"))

	Luau.lua_settable(L, -3)

	Luau.lua_pop(L, 1) -- pop dequeue
end

--[[
	Core scheduler loop.
]]
function Scheduler.schedule(L: Luau.LuaState): ()
	Luau.lua_getfield(L, Luau.LUA_REGISTRYINDEX, INACTIVE_THREAD_DEQUEUE)
	Luau.lua_setfield(L, Luau.LUA_REGISTRYINDEX, ACTIVE_THREAD_DEQUEUE)
	Scheduler.reset(L, INACTIVE_THREAD_DEQUEUE)

	Luau.lua_getfield(L, Luau.LUA_REGISTRYINDEX, ACTIVE_THREAD_DEQUEUE) -- +1: queue

	Luau.lua_getfield(L, -1, Wasm.cstr("first")) -- +1: first
	local dQueueFirst = Luau.lua_tonumberx(L, -1)

	Luau.lua_getfield(L, -2, Wasm.cstr("last")) -- +1: last
	local dQueueLast = Luau.lua_tonumberx(L, -1)

	Luau.lua_pop(L, 2) -- pop first, last

	while dQueueFirst <= dQueueLast do
		Luau.lua_pushinteger(L, dQueueFirst + 1)
		Luau.lua_setfield(L, -2, Wasm.cstr("first"))

		Luau.lua_pushinteger(L, dQueueFirst)
		Luau.lua_gettable(L, -2) -- +1: table

		Luau.lua_getfield(L, -1, Wasm.cstr("thread")) -- +1 thread

		local thread = Luau.lua_tothread(L, -1)
		Luau.lua_pop(L, 1) -- pop thread

		-- sometimes the thread is just not valid.
		if Luau.lua_status(thread) == Luau.LUA_YIELD then
			Luau.lua_getfield(L, -1, Wasm.cstr("args")) -- +1 args

			local argCount = Luau.lua_objlen(L, -1)

			for i = 1, argCount do
				Luau.lua_rawgeti(L, -1, i)
			end

			local status = Luau.lua_resume(thread, L, argCount)

			if status == Luau.LUA_YIELD then
				Scheduler.pushBack(L, thread)
			elseif status ~= Luau.LUA_OK then
				if status == Luau.LUA_ERRRUN then
					print(`Runtime error: {Wasm.luastr(Luau.lua_tostring(thread, -1))}`)

					Luau.lua_pop(L, 1)
				elseif status == Luau.LUA_ERRMEM then
					print(`Memory error!`)
				elseif status == Luau.LUA_ERRSYNTAX then
					print(`Syntax error!`)
				end
			end
		end

		Luau.lua_pop(L, Luau.lua_gettop(L) - 1)

		Luau.lua_getfield(L, -1, Wasm.cstr("first")) -- +1: first
		dQueueFirst = Luau.lua_tonumberx(L, -1)

		Luau.lua_getfield(L, -2, Wasm.cstr("last")) -- +1: last
		dQueueLast = Luau.lua_tonumberx(L, -1)

		Luau.lua_pop(L, 2) -- pop first, last
	end
end

--[[
	Will reset a dequeue back to it's default state.
]]
function Scheduler.reset(L: Luau.LuaState, queue: Wasm.Pointer): ()
	Luau.lua_newtable(L)

	Luau.lua_pushinteger(L, 0)
	Luau.lua_setfield(L, -2, Wasm.cstr("first"))

	Luau.lua_pushinteger(L, -1)
	Luau.lua_setfield(L, -2, Wasm.cstr("last"))

	Luau.lua_setfield(L, Luau.LUA_REGISTRYINDEX, queue)
end

--[[
	Will initialise the dequeues for this lua state.
]]
function Scheduler.init(L: Luau.LuaState): ()
	Scheduler.reset(L, ACTIVE_THREAD_DEQUEUE)
	Scheduler.reset(L, INACTIVE_THREAD_DEQUEUE)
end

return Scheduler
