--[[
	Responsible for implementing the Roblox Runtime environment.
]]

local Scheduler = require("../modules/Scheduler")

return function(sandbox)
	sandbox:LoadEnvironment("Luau")
	sandbox:LoadLibrary("async")

	Scheduler.init(sandbox.L)

	sandbox:LoadBlob("task")
	sandbox:LoadBlob("pp")

	sandbox:AddToScheduler(function()
		Scheduler.schedule(sandbox.L)
	end)
end
