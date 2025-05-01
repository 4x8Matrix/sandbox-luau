# Sandbox

Sandbox is essentially a Luau Runtime that has compatability with the Roblox Luau Runtime, ontop of this; provides
an environment that can be configured to emulate Roblox, UNC, or plain old simple Luau.

### Development

Sandbox is currently in development and is not yet ready for use.

### Example

An example of how this sandbox works in Roblox:
```lua
local SandboxLuau = require(ReplicatedStorage.Packages.SandboxLuau)
local Sandbox = SandboxLuau.new()

-- scheduler
task.spawn(function()
  while task.wait(0) do
    Sandbox:Schedule()
  end
end)

-- load environment
Sandbox:LoadEnvironment("Roblox")

-- run code
Sandbox:Eval([[
local Players = game:GetService("Players")

print(Players.LocalPlayer.Name)

task.wait(5)

print("5 seconds have passed!")
]])
```

Alternatively, an example of how this sandbox works in UNC:
```lua
local SandboxLuau = require(ReplicatedStorage.Packages.SandboxLuau)
local Sandbox = SandboxLuau.new()


-- scheduler
task.spawn(function()
  while task.wait(0) do
    Sandbox:Schedule()
  end
end)

-- load environment
Sandbox:LoadEnvironment("UNC")

-- run code
Sandbox:Eval([[
for _, object in getgc() do
  print(`{tostring(object)} is currently in the GC for the UNC rt!`)
end

writefile("file.txt", "Hello, world!")
print(readfile("file.txt")) --> Hello, world!
]])
```