--[[
	Roblox Env: responsible for implementing the same environment as the Roblox runtime.
]]

return [[
local startTime = os.clock()
local registry = runtime.registry()

glob.set("ypcall", pcall)
glob.set("wait", task.wait)
glob.set("spawn", task.spawn)
glob.set("delay", task.delay)
glob.set("tick", os.clock)
glob.set("time", os.clock)

glob.set("elapsedTime", closures.cClosure(function()
	return os.clock() - startTime
end))

glob.set("ElapsedTime", closures.cClosure(function()
	return os.clock() - startTime
end))

glob.set("PluginManager", closures.cClosure(function()
	-- error("PluginManager is not implemented")
end))

glob.set("DebuggerManager", closures.cClosure(function()
	-- error("DebuggerManager is not implemented")
end))

glob.environment(setmetatable({
	_G = { },
	shared = { }
}, { __index = _G, __metatable = "The metatable is locked" }))

glob.set("closures", nil)
glob.set("runtime", nil)
glob.set("glob", nil)
]]
