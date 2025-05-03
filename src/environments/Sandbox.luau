--[[
	Responsible for implementing a custom Runtime, primarily just for testing/fun.
]]

local Scheduler = require("../modules/Scheduler")

return function(sandbox)
	sandbox:LoadEnvironment("Luau")
	sandbox:LoadLibrary("async")
	sandbox:LoadLibrary("glob")

	Scheduler.init(sandbox.L)

	sandbox:LoadBlob("standard_pp")

	sandbox:AddToScheduler(function()
		Scheduler.schedule(sandbox.L)
	end)
end
