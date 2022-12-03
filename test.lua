#!/usr/bin/lua

local function run()
	package.path = table.concat({
		"./lua/?.lua",
		"./third-party/?.lua",
		"./third-party/jean-lua/lua/?.lua",
		"./tests/?.lua",
	}, ";") .. ";" .. package.path

	pcall(function()
		require("luacov")
		print("Loaded luacov\n")
	end)

	local suites = {
		"buffer-tests",
		"bound-context-tests",
		"context-tests",
		"path-tests",
	}

	-- To make assert functions globally accessible
	for key, value in pairs(require("luaunit")) do
		_G[key] = value
	end

	for _, suite in ipairs(suites) do
		_G[suite] = require(suite)
	end

	function LuaUnit.isMethodTestName()
		return true
	end

	function LuaUnit.isTestName(name)
		for _, suite in ipairs(suites) do
			if suite == name then
				return true
			end
		end
		return false
	end

	return LuaUnit.run()
end

local status, result = pcall(run)

if not status then
	print(result)
	os.exit(-1)
end

os.exit(result)
