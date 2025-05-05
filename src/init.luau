--[=[
	@class Sandbox

	Sandbox is essentially a Luau Runtime that has compatability with the Roblox Luau Runtime, ontop of this; provides
	an environment that can be configured to emulate Roblox, UNC, or plain old simple Luau.

	Sandbox is designed to be begginer friendly, and essentially wraps around the LuauCeption module, please go give this
	project some love - without LuauCeption this project would not be possible.

	> https://github.com/RadiatedExodus/LuauCeption

	An example of how to use this module can be found below:
	```lua
	local Sandbox = SandboxLuau.new()

	Sandbox:LoadEnvironment("Roblox")
	Sandbox:Eval([[
		print(game.Workspace:GetAttribute("Wahoo!"))
	]])
	```
]=]

local Luau = require("./modules/Luau")
local Wasm = require("./modules/Wasm")
local Reflector = require("./modules/Reflector")

local resumeWithErrorHandling = require("./functions/resumeWithErrorHandling")

local require = require :: any

local SandboxLuau = {}

SandboxLuau.Interface = {}
SandboxLuau.Prototype = {}

--[=[
	@within Sandbox

	There are several libraries that can be loaded in order to give the sandbox additional functionality.
	For example, if you wanted the ability to asynchronously run code, you would add the `async` library;

	```lua
	local Sandbox = SandboxLuau.new()

	Sandbox:LoadLibrary("async")

	...

	Sandbox:Eval([[
		local clock = os.clock()

		while os.clock() - clock < 5 do
			-- don't block lua! Just sleep this thread until the scheduler wakes it up on the next execution cycle!
			async.await()
		end

		print("5 seconds have passed!")
	]])
	```
]=]
function SandboxLuau.Prototype.LoadLibrary(self: Sandbox, library: Library): ()
	local callback

	if script then
		callback = require((script :: any).libraries[library])
	else
		callback = require(`./libraries/{library}`)
	end

	callback(self)
end

--[=[
	@within Sandbox

	This function is where Sandbox really shows off it's capabilitues, this function enables you to load an entire environment;
		what this enables us to do is emulate a Roblox Luau Runtime, UNC, or any other environment that's been added to the Sandbox.

	If you don't load an environment, your code will be very limited, it won't even have access to standard library functions such as `print`.
	If you'd like these functions, you'll need to load the `Luau` environment.

	---

	It's worth notingh that environments can depend on one another, the Roblox environment depends on the Luau environment, the
	UNC environment depends on the Roblox environment, and so on..
]=]
function SandboxLuau.Prototype.LoadEnvironment(self: Sandbox, env: Environment): ()
	local callback

	if script then
		callback = require((script :: any).environments[env])
	else
		callback = require(`./environments/{env}`)
	end

	table.insert(self.Environments, env)

	callback(self)
end

--[=[
	@within Sandbox

	Blobs represent a chunk of code that is compiled and executed by the sandbox before the user has evaluated any code, this is typically
	done in order to replace globals, modify the environment or change how the environment works within Luau before the user has
	accessed the environment.

	Example of this can be `pp`, which is a pretty printer for Luau code;

	```lua
	local Sandbox = SandboxLuau.new()

	Sandbox:Eval([[
		print({ Hey = "Hello World!" })
	]]) --> table: 0x00000000000xxxxx
	```

	```lua
	local Sandbox = SandboxLuau.new()

	-- pp even supports colors!
	Sandbox:LoadBlob("pp")

	Sandbox:Eval([[
	print({ Hey = "Hello World!" })
	]]) --> {
	--			Hey = "Hello World!"
	-- 		}
]=]
function SandboxLuau.Prototype.LoadBlob(self: Sandbox, blob: Blob): ()
	local blobData

	if script then
		blobData = require((script :: any).blobs[blob])
	else
		blobData = require(`./blobs/{blob}`)
	end

	self:Eval(blobData)
end

--[=[
	@within Sandbox

	This function enables developers to bind functions to the sandboxes scheduler, to further understand how the sandboxes scheduler
		works, please see the `Schedule` function. 

	This is typically called from in-house environments such as the Roblox environment, from here - we then power the sandbox's scheduler
		which in turn makes all the concurrent tasks run!
]=]
function SandboxLuau.Prototype.AddToScheduler(self: Sandbox, task: () -> ()): ()
	table.insert(self.Scheduled, task)
end

--[=[
	@@within Sandbox

	The scheduler in Sandbox is a little difficult to grasp, but essentially it's a way to run concurrent tasks. You call this function;
		and it'll run all the tasks that have been added to the scheduler.

	This means that you need to set something up, on whatever runtime you're using, to call this function... 

	For example, if I were in Roblox, using this Sandbox package, I would suggest doing:

	```lua
	local Sandbox = SandboxLuau.new()

	task.spawn(function()
		while task.wait(0) do
			-- every time Roblox schedules an update - we'll ask the sandbox's scheduler to update!
			Sandbox:Schedule()
		end
	end)

	...
	```

	---

	As an aside, this function essentially just calls anything that has binded to the sandbox's list of "scheduled" tasks.
		And when you call LoadEnvironment, we call the `AddToScheduler` function, which then adds the function to the
		list of tasks that wil be called upn when you call the `Schedule` function!
]=]
function SandboxLuau.Prototype.Schedule(self: Sandbox)
	for _, task in self.Scheduled do
		task()
	end
end

--[=[
	@within Sandbox

	Will compile the Luau code into bytecode, return the pointer to the bytecode, and the size of the bytecode.
		This pointer - points towards the string in the wasm memory, if you wanted to get the bytecode as a lua string,
		you'd need to call Wasm.luastring(bytecodePtr)
]=]
function SandboxLuau.Prototype.Compile(
	_: Sandbox,
	code: string,
	settings: {
		optimisationLevel: number?,
		debugLevel: number?,
		coverageLevel: number?,
		typeInfoLevel: number?,
	}?
): (Wasm.Pointer, number)
	local compileOptionsPtr = Luau.malloc(36)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr, settings and settings.optimisationLevel or 1)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 4, settings and settings.debugLevel or 1)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 8, settings and settings.typeInfoLevel or 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 12, settings and settings.coverageLevel or 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 16, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 20, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 24, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 28, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 32, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 36, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 40, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 44, 0)
	Wasm.rt.store.i32(Wasm.memory, compileOptionsPtr + 48, 0)

	local bytecodeSizePtr = Luau.malloc(8)
	local bytecodePtr = Luau.luau_compile(Wasm.cstr(code), #code, compileOptionsPtr, bytecodeSizePtr)
	local bytecodeSize = Wasm.rt.load.i32(Wasm.memory, bytecodeSizePtr)

	Luau.free(bytecodeSizePtr)
	Luau.free(compileOptionsPtr)

	return bytecodePtr, bytecodeSize
end

--[=[
	@within Sandbox

	The primary function used for evaluating Luau code. Luau code, when ran here will run in the environment, with
		all the configurations applied.
]=]
function SandboxLuau.Prototype.Eval(
	self: Sandbox,
	code: string,
	settings: {
		chunkName: string?,

		optimisationLevel: number?,
		debugLevel: number?,
		coverageLevel: number?,
		typeInfoLevel: number?,
	}?
)
	if #self.Environments == 0 then
		print(
			`No environments loaded, your luau code will be fairly limited - try ':LoadLibrary' to load an environment.`
		)
	end

	local thread = Luau.lua_newthread(self.L)
	Luau.lua_pop(self.L, 1)

	local namePtr = Wasm.cstr(settings and settings.chunkName or "SandboxChunk")
	local bytecodePtr, bytecodeSize = self:Compile(code, settings)

	local result = Luau.luau_load(thread, namePtr, bytecodePtr, bytecodeSize, 0)

	Luau.free(bytecodePtr)
	Luau.free(namePtr)

	if result ~= 0 then
		print(`Luau.luau_load failed with code {result}`)

		return
	end

	Luau.lua_getfield(thread, Luau.LUA_REGISTRYINDEX, Wasm.cstr("__ENV")) -- +1: env

	if Luau.lua_istable(thread, -1) == 1 then
		Luau.lua_pushvalue(thread, -1)
		Luau.lua_setfenv(thread, -3)
	end

	Luau.lua_pop(thread, 1) -- pop env

	resumeWithErrorHandling(thread, self.L, 0)

	return Reflector.reflectFrom(thread, -1)
end

--[=[
	@within Sandbox

	Will construct a new sandbox instance, then returns said instance.
]=]
function SandboxLuau.Interface.new(): Sandbox
	local self = setmetatable({} :: Sandbox, { __index = SandboxLuau.Prototype })
	local void = nil :: any

	self.L = Luau.luaL_newstate(void, void)
	self.Environments = {}
	self.Scheduled = {}

	return self
end

export type Reference<T> = number
export type Environment = "Luau" | "Roblox" | "UNC" | "Sandbox"
export type Library = "async"
export type Blob = "pp" | "task"

export type Sandbox = typeof(SandboxLuau.Prototype) & {
	L: Reference<"LuaState">,
	Environments: { Environment },
	Scheduled: { () -> () },
}

return SandboxLuau.Interface
