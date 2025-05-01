--[[
	Luau bindings to LuauCeption, this is essentially just a wrapper around the wasm functions that LuauCeption exports.
]]

local LuauCeption = require("../vendor/LuauCeption")

local library = setmetatable({}, { __index = LuauCeption.wasm.cfns })

library.LUAI_MAXCSTACK = 8000
library.LUA_REGISTRYINDEX = -library.LUAI_MAXCSTACK - 2000
library.LUA_ENVIRONINDEX = -library.LUAI_MAXCSTACK - 2001
library.LUA_GLOBALSINDEX = -library.LUAI_MAXCSTACK - 2002
library.LUA_VECTOR_SIZE = 3

library.LUA_TNIL = 0
library.LUA_TBOOLEAN = 1
library.LUA_TLIGHTUSERDATA = 2
library.LUA_TNUMBER = 3
library.LUA_TVECTOR = 4
library.LUA_TSTRING = 5
library.LUA_TTABLE = 6
library.LUA_TFUNCTION = 7
library.LUA_TUSERDATA = 8
library.LUA_TTHREAD = 9
library.LUA_TBUFFER = 10
library.LUA_TPROTO = 11
library.LUA_TUPVAL = 12
library.LUA_TDEADKEY = 13
library.LUA_T_COUNT = library.LUA_TPROTO

library.LUA_OK = 0
library.LUA_YIELD = 1
library.LUA_ERRRUN = 2
library.LUA_ERRSYNTAX = 3
library.LUA_ERRMEM = 4
library.LUA_ERRERR = 5
library.LUA_BREAK = 6

library.LUA_CORUN = 0
library.LUA_COSUS = 1
library.LUA_CONOR = 2
library.LUA_COFIN = 3
library.LUA_COERR = 4

library.LUA_GCSTOP = 0
library.LUA_GCRESTART = 1
library.LUA_GCCOLLECT = 2
library.LUA_GCCOUNT = 3
library.LUA_GCCOUNTB = 4
library.LUA_GCISRUNNING = 5
library.LUA_GCSTEP = 6
library.LUA_GCSETGOAL = 7
library.LUA_GCSETSTEPMUL = 8
library.LUA_GCSETSTEPSIZE = 9

library.LUA_IDSIZE = 256
library.LUA_MINSTACK = 20
library.LUAI_MAXCALLS = 20000
library.LUAI_MAXCCALLS = 200
library.LUA_BUFFERSIZE = 512
library.LUA_UTAG_LIMIT = 128
library.LUA_LUTAG_LIMIT = 128
library.LUA_SIZECLASSES = 40
library.LUA_MEMORY_CATEGORIES = 256
library.LUA_MINSTRTABSIZE = 32
library.LUA_MAXCAPTURES = 32
library.LUA_VECTOR_SIZE = 3
library.LUA_EXTRA_SIZE = library.LUA_VECTOR_SIZE - 2
library.LUA_MULTRET = -1
library.LUA_TNONE = -1
library.LUA_NOREF = -1
library.LUA_REFNIL = 0
library.LUA_COLIBNAME = "coroutine"
library.LUA_TABLIBNAME = "table"
library.LUA_OSLIBNAME = "os"
library.LUA_STRLIBNAME = "string"
library.LUA_BITLIBNAME = "bit32"
library.LUA_BUFFERLIBNAME = "buffer"
library.LUA_UTF8LIBNAME = "utf8"
library.LUA_MATHLIBNAME = "math"
library.LUA_DBLIBNAME = "debug"
library.LUA_VECLIBNAME = "vector"

library.lua_upvalueindex = function(i)
	return library.LUA_GLOBALSINDEX - i
end
library.lua_ispseudo = function(i)
	return if i <= library.LUA_REGISTRYINDEX then 1 else 0
end
library.lua_getref = function(L, ref)
	return LuauCeption.wasm.cfns.lua_rawgeti(L, library.LUA_REGISTRYINDEX, ref)
end
library.lua_tonumberx = function(L, i)
	return LuauCeption.wasm.cfns.lua_tonumberx(L, i, 0)
end
library.lua_tointegerx = function(L, i)
	return LuauCeption.wasm.cfns.lua_tointegerx(L, i, 0)
end
library.lua_pop = function(L, n)
	return LuauCeption.wasm.cfns.lua_settop(L, -n - 1)
end
library.lua_newtable = function(L)
	return LuauCeption.wasm.cfns.lua_createtable(L, 0, 0)
end
library.lua_newuserdata = function(L, s)
	return LuauCeption.wasm.cfns.lua_newuserdatatagged(L, s, 0)
end
library.lua_strlen = function(L, i)
	return LuauCeption.wasm.cfns.lua_objlen(L, i)
end
library.lua_isfunction = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TFUNCTION then 1 else 0
end
library.lua_istable = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TTABLE then 1 else 0
end
library.lua_islightuserdata = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TLIGHTUSERDATA then 1 else 0
end
library.lua_isnil = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TNIL then 1 else 0
end
library.lua_isboolean = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TBOOLEAN then 1 else 0
end
library.lua_isvector = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TVECTOR then 1 else 0
end
library.lua_isthread = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TTHREAD then 1 else 0
end
library.lua_isbuffer = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TBUFFER then 1 else 0
end
library.lua_isnone = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) == library.LUA_TNONE then 1 else 0
end
library.lua_isnoneornil = function(L, n)
	return if LuauCeption.wasm.cfns.lua_type(L, n) <= library.LUA_TNIL then 1 else 0
end
library.lua_pushcfunction = function(L, fn, debugname)
	return LuauCeption.wasm.cfns.lua_pushcclosurek(L, fn, debugname, 0, 0)
end
library.lua_pushcclosure = function(L, fn, debugname, nup)
	return LuauCeption.wasm.cfns.lua_pushcclosurek(L, fn, debugname, nup, 0)
end
library.lua_pushlightuserdata = function(L, p)
	return LuauCeption.wasm.cfns.lua_pushlightuserdatatagged(L, p, 0)
end
library.lua_setglobal = function(L, s)
	return LuauCeption.wasm.cfns.lua_setfield(L, library.LUA_GLOBALSINDEX, s)
end
library.lua_getglobal = function(L, s)
	return LuauCeption.wasm.cfns.lua_getfield(L, library.LUA_GLOBALSINDEX, s)
end
library.lua_tostring = function(L, i)
	return LuauCeption.wasm.cfns.lua_tolstring(L, i, 0)
end
library.lua_pushfstring = function(L, fmt, ...)
	return LuauCeption.wasm.cfns.lua_pushfstringL(L, fmt, ...)
end
library.luaL_error = function(L, fmt, ...)
	return LuauCeption.wasm.cfns.luaL_errorL(L, fmt, ...)
end
library.luaL_typeerror = function(L, narg, tname)
	return LuauCeption.wasm.cfns.luaL_typeerrorL(L, narg, tname)
end
library.luaL_argerror = function(L, narg, extramsg)
	return LuauCeption.wasm.cfns.luaL_argerrorL(L, narg, extramsg)
end
library.luaL_argcheck = function(L, cond, arg, extramsg)
	return if cond == 1 then 0 else LuauCeption.wasm.cfns.luaL_argerrorL(L, arg, extramsg)
end
library.luaL_argexpected = function(L, cond, arg, tname)
	return if cond == 1 then 0 else LuauCeption.wasm.cfns.luaL_typeerrorL(L, arg, tname)
end
library.luaL_checkstring = function(L, n)
	return LuauCeption.wasm.cfns.luaL_checklstring(L, n, 0)
end
library.luaL_optstring = function(L, n, d)
	return LuauCeption.wasm.cfns.luaL_optlstring(L, n, d, 0)
end
library.luaL_getmetatable = function(L, n)
	return LuauCeption.wasm.cfns.lua_getfield(L, library.LUA_REGISTRYINDEX, n)
end
library.luaL_addstring = function(B, s)
	return LuauCeption.wasm.cfns.luaL_addlstring(B, s, LuauCeption.wasm.cfns.strlen(s))
end

export type LuaState = number
export type LuaThread = number

return library
