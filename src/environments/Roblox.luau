--[[
	Responsible for implementing the Roblox Runtime environment.
]]

local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")
local Scheduler = require("../modules/Scheduler")
local Reflector = require("../modules/Reflector")
local Cache = require("../modules/Cache")

return function(sandbox)
	sandbox:LoadEnvironment("Luau")
	sandbox:LoadLibrary("async")
	sandbox:LoadLibrary("glob")
	sandbox:LoadLibrary("closures")
	sandbox:LoadLibrary("runtime")

	Scheduler.init()
	Cache.init(sandbox.L)
	Reflector.init(sandbox.L)

	do -- userdatas
		Luau.lua_pushcfunction(
			sandbox.L,
			Wasm.cfn(function(L)
				Reflector.reflectUserdataInto(L, UserSettings())

				return 1
			end),
			Wasm.cstr("")
		)
		Luau.lua_setglobal(sandbox.L, Wasm.cstr("UserSettings"))

		Luau.lua_pushcfunction(
			sandbox.L,
			Wasm.cfn(function(L)
				Reflector.reflectUserdataInto(L, settings())

				return 1
			end),
			Wasm.cstr("")
		)
		Luau.lua_setglobal(sandbox.L, Wasm.cstr("settings"))

		Luau.lua_pushcfunction(
			sandbox.L,
			Wasm.cfn(function(L)
				local stack = Luau.lua_gettop(L)
				local str = ""

				for index = 1, stack do
					str ..= `{index ~= 1 and " " or ""}{Wasm.luastr(Luau.lua_tostring(L, index))}`
				end

				warn(str)

				return 0
			end),
			Wasm.cstr("")
		)
		Luau.lua_setglobal(sandbox.L, Wasm.cstr("warn"))

		for index, value in
			{
				game = game,
				workspace = workspace,
				script = script,
			} :: { [string]: any }
		do
			Reflector.reflectUserdataInto(sandbox.L, value)
			Luau.lua_setglobal(sandbox.L, Wasm.cstr(index))
		end
	end

	do -- datatypes
		for index, value in
			{
				Vector3 = Vector3,
				Vector2 = Vector2,
				Vector3int16 = Vector3int16,
				Vector2int16 = Vector2int16,
				CFrame = CFrame,
				Color3 = Color3,
				BrickColor = BrickColor,
				Ray = Ray,
				Region3 = Region3,
				Region3int16 = Region3int16,
				Instance = Instance,
				Axes = Axes,
				Faces = Faces,
				Enum = Enum,
				Random = Random,
				TweenInfo = TweenInfo,
				UDim = UDim,
				UDim2 = UDim2,
				NumberRange = NumberRange,
				NumberSequence = NumberSequence,
				NumberSequenceKeypoint = NumberSequenceKeypoint,
				ColorSequence = ColorSequence,
				ColorSequenceKeypoint = ColorSequenceKeypoint,
				RaycastParams = RaycastParams,
				OverlapParams = OverlapParams,
				PhysicalProperties = PhysicalProperties,
				PathWaypoint = PathWaypoint,
				Path2DControlPoint = Path2DControlPoint,
				DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo,
				CatalogSearchParams = CatalogSearchParams,
				Content = Content,
				DateTime = DateTime,
				FloatCurveKey = FloatCurveKey,
				Font = Font,
				Rect = Rect,
				RotationCurveKey = RotationCurveKey,
				SharedTable = SharedTable,
			} :: { [string]: any }
		do
			Reflector.reflectInto(sandbox.L, value)
			Luau.lua_setglobal(sandbox.L, Wasm.cstr(index))
		end
	end

	sandbox:LoadBlob("roblox_pp")
	sandbox:LoadBlob("roblox_task")
	sandbox:LoadBlob("roblox_env")

	sandbox:AddToScheduler(function()
		Scheduler.schedule()
	end)
end
