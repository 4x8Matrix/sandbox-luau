--[[
	Task: A Luau implementation of the Roblox task library that provides concurrent scheduling functionality.
	This module implements task.spawn, task.defer, and task.delay to match Roblox's behavior using coroutines.
]]

return [[
local async = async

task = {}

local function resume(co, ...)
	local object = { coroutine.resume(co, ...) }

	local success = table.remove(object, 1)

	if not success then
		print(`Coroutine Error:`, object)
	end
end

function task.spawn(f, ...)
	local co = coroutine.create(f)

	resume(co, ...)
end

function task.defer(f, ...)
	local co = coroutine.create(function(...)
		async.await()

		f(...)
	end)

	resume(co, ...)
end

function task.delay(timeToDelay, f, ...)
	local clock = os.clock()

	local co = coroutine.create(function(...)
		if timeToDelay and timeToDelay > 0 then
			while os.clock() - clock < timeToDelay do
				async.await()
			end
		else
			async.await()
		end

		f(...)
	end)

	resume(co, ...)
end

function task.desynchronize()
	print(`task.desynchronize has not been implemented yet.`)
end

function task.synchronize()
	print(`task.synchronize has not been implemented yet.`)
end

function task.wait(timeToDelay)
	local clock = os.clock()

	if timeToDelay and timeToDelay > 0 then
		while os.clock() - clock < timeToDelay do
			async.await()
		end
	else
		async.await()
	end

	return os.clock() - clock
end

function task.cancel(co)
	coroutine.close(co)
end

glob.set("task", task)
glob.set("async", nil)
]]
