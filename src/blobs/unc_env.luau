--[[
	Unc Env
]]

return [=[
local vfs = {}
local hiFolder

glob.set("readfile", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if index == #components then
			break
		end

		root = root[head]
	end

	return root[components[#components]]
end))

glob.set("listfiles", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end

	local files = {}

	for fileName, data in root do
		table.insert(files, `{path}/{fileName}`)
	end

	return files
end))

glob.set("writefile", closures.cClosure(function(path: string, data: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if index == #components then
			break
		end

		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end

	root[components[#components]] = data
end))

glob.set("makefolder", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end
end))

glob.set("appendfile", closures.cClosure(function(path: string, data: string)
	writefile(path, readfile(path) .. data)
end))

glob.set("isfile", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if index == #components then
			break
		end

		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end

	return type(root[components[#components]]) == "string"
end))

glob.set("isfolder", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if index == #components then
			break
		end

		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end

	return type(root[components[#components]]) == "table"
end))

glob.set("delfolder", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if index == #components then
			break
		end

		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end

	root[components[#components]] = nil
end))

glob.set("delfile", closures.cClosure(function(path: string)
	local components = string.split(path, "/")
	local root = vfs

	for index, head in components do
		if index == #components then
			break
		end

		if not root[head] then
			root[head] = {}
		end

		root = root[head]
	end

	root[components[#components]] = nil
end))

glob.set("clonefunction", closures.cClosure(function(caller)
	return function(...)
		return caller(...)
	end
end))

glob.set("checkcaller", closures.cClosure(function()
	return true
end))

glob.set("iscclosure", closures.cClosure(function(f)
	return debug.info(f, "s") ~= "[C]"
end))

glob.set("iscclosure", closures.cClosure(function(f)
	return debug.info(f, "s") == "[C]"
end))

glob.set("newcclosure", closures.cClosure(function(f)
	return closures.cClosure(function(...)
		return f(...)
	end)
end))

glob.set("rconsoleclear", closures.cClosure(function(f) end))

glob.set("rconsolecreate", closures.cClosure(function(f) end))

glob.set("rconsoledestroy", closures.cClosure(function(f) end))

glob.set("rconsoleinput", closures.cClosure(function(f) end))

glob.set("rconsoleprint", closures.cClosure(function(f) end))

glob.set("mouse1click", closures.cClosure(function(f) end))

glob.set("mouse1press", closures.cClosure(function(f) end))

glob.set("mouse1release", closures.cClosure(function(f) end))

glob.set("mouse2click", closures.cClosure(function(f) end))

glob.set("mouse2press", closures.cClosure(function(f) end))

glob.set("mouse2release", closures.cClosure(function(f) end))

glob.set("mousemoveabs", closures.cClosure(function(f) end))

glob.set("mousemoverel", closures.cClosure(function(f) end))

glob.set("mousescroll", closures.cClosure(function(f) end))

glob.set("fireclickdetector", closures.cClosure(function(f) end))

glob.set("messagebox", closures.cClosure(function(f) end))

glob.set("setclipboard", closures.cClosure(function(f) end))

glob.set("setrbxclipboard", closures.cClosure(function(f) end))

glob.set("queue_on_teleport", closures.cClosure(function(f) end))

glob.set("identifyexecutor", closures.cClosure(function(f)
	return "Sandbox-Luau", "-1"
end))
]=]
