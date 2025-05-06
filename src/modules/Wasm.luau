--[[
	Luau bindings to LuauCeption, this is essentially just a wrapper around the wasm table that LuauCeption exports. In addition this module
	may also tinker with the wasm runtime.
]]

local LuauCeption = require("../vendor/LuauCeption")

local strings = {}

local library = setmetatable({}, { __index = LuauCeption.wasm })

function library.cstr(source: string): Pointer
	if strings[source] then
		return strings[source]
	else
		local stringLength = #source
		local stringPointer = LuauCeption.wasm.cfns.malloc(stringLength + 1)

		LuauCeption.wasm.rt.store.string(LuauCeption.wasm.memory, stringPointer, source)
		LuauCeption.wasm.rt.store.i32_n8(LuauCeption.wasm.memory, stringPointer + stringLength, 0)

		strings[source] = stringPointer

		return strings[source]
	end
end

function library.luastr(pointer): string
	local stringLength = LuauCeption.wasm.cfns.strlen(pointer)

	return buffer.readstring(LuauCeption.wasm.memory.data, pointer, stringLength)
end

function library.cfn(source: (...any) -> Pointer)
	local pointer = #LuauCeption.wasm.indirect_function_table.data + 1

	LuauCeption.wasm.indirect_function_table.data[pointer] = function(L, ...)
		local status, result = pcall(function(...)
			return source(L, ...)
		end, ...)

		if type(result) ~= "number" then
			error(`Return value must be a number ({debug.info(source, "s")} - {debug.info(source, "lnaf")})`)
		end

		if not status then
			LuauCeption.wasm.cfns.lua_pushstring(L, library.cstr("Error: " .. result))
			LuauCeption.wasm.cfns.lua_error(L)

			return 1
		end

		return result
	end

	return pointer
end

export type Pointer = number

return library
