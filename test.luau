local task = require("@lune/task")

local SandboxLuau = require("./src")

local Sandbox = SandboxLuau.new()

task.spawn(function()
	while task.wait(0) do
		Sandbox:Schedule()
	end
end)

Sandbox:LoadEnvironment("Roblox")
Sandbox:Eval([[
-- setfenv(0, {})

-- print("hi", e)
a = game.e
]])
