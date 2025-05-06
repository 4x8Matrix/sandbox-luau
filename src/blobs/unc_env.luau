--[[
	Unc Env
]]

return [[
glob.set("clonefunction", function(caller)
    return function(...)
        return caller(...)
    end
end)

glob.set("checkcaller", closures.cClosure(function()
	return true
end))
]]
