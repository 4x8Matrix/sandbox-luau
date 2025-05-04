local task = require("@lune/task")

local SandboxLuau = require("./src")

local Sandbox = SandboxLuau.new()

task.spawn(function()
	while task.wait(0.5) do
		Sandbox:Schedule()
	end
end)

Sandbox:LoadEnvironment("Sandbox")
Sandbox:Eval([[
while true do
	async.defer()

	print("e")
end
]])
