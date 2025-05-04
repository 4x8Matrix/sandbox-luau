--[[
	Async library for Luau, implements concurrency in Luau.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")
local Scheduler = require("../modules/Scheduler")

--[[
	Defer will yield the current thread until the next execution cycle.
]]
local function defer(L)
	Luau.lua_pushthread(L) -- +1: thread
	local thread = Luau.lua_tothread(L, -1)
	Luau.lua_pop(L, 1) -- pop thread

	Scheduler.pushFront(coroutine.create(function()
		Luau.lua_resume(thread, L, 0)
	end))

	return Luau.lua_yield(L, 0)
end

--[[
	Await will yield the current thread until the end of the current execution cycle.
]]
local function await(L)
	Luau.lua_pushthread(L) -- +1: thread
	local thread = Luau.lua_tothread(L, -1)
	Luau.lua_pop(L, 1) -- pop thread

	Scheduler.pushBack(coroutine.create(function()
		Luau.lua_resume(thread, L, 0)
	end))

	return Luau.lua_yield(L, 0)
end

return function(sandbox)
	Luau.lua_newtable(sandbox.L)

	for name, callback in
		{
			defer = defer,
			await = await,
		} :: { [string]: any }
	do
		Luau.lua_pushcfunction(sandbox.L, Wasm.cfn(callback), Wasm.cstr(name))
		Luau.lua_setfield(sandbox.L, -2, Wasm.cstr(name))
	end

	Luau.lua_setglobal(sandbox.L, Wasm.cstr("async"))
end
