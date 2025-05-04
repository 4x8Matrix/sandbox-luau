--[[
	Welcome to the scheduler! This module is responsible for handling the concurrency embedded into the
	sandboxes runtime.

	This scheduler uses a double ended queue to be able to define two sorts of behaviours: 
		1. Defferred threads, these are threads that will be resumed at the end of the current exeuction cycle.
		2. Awaiting threads, these are threads that will be resumed at the start of the current exeuction cycle.
]]

local schedulerDequeue: Dequeue
local dequeueSize: number

local Scheduler = {}

--[[
	Will push a thread to the start of the dequeue.
]]
function Scheduler.pushFront(thread: thread): ()
	schedulerDequeue.first -= 1
	schedulerDequeue.queue[schedulerDequeue.first] = thread

	dequeueSize += 1
end

--[[
	Will push a thread to the end of the dequeue.
]]
function Scheduler.pushBack(thread: thread): ()
	schedulerDequeue.last += 1
	schedulerDequeue.queue[schedulerDequeue.last] = thread

	dequeueSize += 1
end

--[[
	Core scheduler loop that runs through all scheduled threads, and resumes them.
]]
function Scheduler.schedule(): ()
	-- we don't want a catch-22 situation where our queue/first/last are ever growing because the thread we resumed then
	-- decided to throw itself back into the queue. So to avoid this, the queue is reset & we store a version of said queue
	-- here.
	local dequeue = schedulerDequeue

	if dequeueSize == 0 then
		return
	end

	Scheduler.reset()

	while dequeue.first <= dequeue.last do
		local thread = dequeue.queue[dequeue.first]
		local success, response = coroutine.resume(thread)

		dequeue.first += 1

		if not success then
			print(`Runtime Error: {response}`)
			print(debug.traceback(thread))
		end
	end
end

--[[
	Responsible for resetting scheduler state.
]]
function Scheduler.reset(): ()
	dequeueSize = 0
	schedulerDequeue = {
		first = 0,
		last = -1,
		queue = {},
	}
end

--[[
	Will initialise scheduler variables.
]]
function Scheduler.init(): ()
	Scheduler.reset()
end

type Queue = { thread }
type Dequeue = {
	first: number,
	last: number,
	queue: Queue,
}

return Scheduler
