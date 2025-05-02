--[[
	Env: 
]]

return [[
local startTime = os.clock()

glob.set("ypcall", closures.cClosure(pcall))
glob.set("wait", closures.cClosure(task.wait))
glob.set("spawn", closures.cClosure(task.spawn))
glob.set("delay", closures.cClosure(task.delay))
glob.set("tick", closures.cClosure(os.clock))
glob.set("time", closures.cClosure(os.clock))

glob.set("elapsedTime", closures.cClosure(function()
	return os.clock() - startTime
end))

glob.set("ElapsedTime", closures.cClosure(function()
	return os.clock() - startTime
end))

glob.set("PluginManager", closures.cClosure(function()
	error("PluginManager is not implemented")
end))

glob.set("DebuggerManager", closures.cClosure(function()
	error("DebuggerManager is not implemented")
end))

glob.set("warn", closures.cClosure(function(...)
	print("WARN:", ...)
end))

glob.environment(setmetatable({
	_G = { },
	shared = { }
}, { __index = _G, __metatable = "The metatable is locked" }))

glob.set("closures", nil)
glob.set("glob", nil)
]]
