local Luau = require("../modules/Luau")
local Wasm = require("../modules/Wasm")

local resumeWithErrorHandling

local function traceback(L, messagePtr)
	Luau.lua_getglobal(L, Wasm.cstr("debug"))
	Luau.lua_getfield(L, -1, Wasm.cstr("traceback"))
	Luau.lua_remove(L, -2)

	Luau.lua_pushstring(L, messagePtr)
	Luau.lua_pushinteger(L, 1)

	Luau.lua_call(L, 2, 1)
end

function resumeWithErrorHandling(thread, from, count, vmTraceback: string?)
	local status = Luau.lua_resume(thread, from, count or 0)

	vmTraceback = vmTraceback or debug.traceback()

	if status == Luau.LUA_YIELD then
		return
	elseif status ~= Luau.LUA_OK then
		if status == Luau.LUA_ERRRUN then
			local errorMessagePtr = Luau.lua_tostring(thread, -1)

			if errorMessagePtr ~= 0 then
				traceback(thread, errorMessagePtr)

				print(`Runtime error: {Wasm.luastr(Luau.lua_tostring(thread, -1))}\n{vmTraceback}`)

				Luau.lua_pop(thread, 2)
			end
		elseif status == Luau.LUA_ERRMEM then
			print(`Memory error!`)
		elseif status == Luau.LUA_ERRSYNTAX then
			print(`Syntax error!`)
		end
	end

	return
end

return resumeWithErrorHandling
