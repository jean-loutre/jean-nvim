local Mock = require("jlua.test.mock")
local Call = require("jlua.test.call")

local ContextHandler = require("jnvim.context-handler")

local Suite = {}

function Suite.bind_function()
	local context = ContextHandler("ott")
	local mock = Mock()

	context.upgrade = mock
	context:bind_function("upgrade")

	assert_false(pcall(function()
		vim.fn["ott#upgrade"]("v2.0")
	end))

	context:enable()
	vim.fn["ott#upgrade"]("v2.0", "turbo-propulser")
	assert(mock.call == Call(context, "v2.0", "turbo-propulser"))

	context:disable()
	assert_false(pcall(function()
		vim.fn["ott#upgrade"]("v2.0", "turbo-propulser")
	end))
end

function Suite.bind_autocommand()
	local context = ContextHandler("ott")
	local mock = Mock()

	context.upgrade = mock
	context:bind_autocommand("User", "upgrade")

	vim.api.nvim_exec_autocmds("User", {})
	assert_equals(mock.calls, {})

	context:enable()
	vim.api.nvim_exec_autocmds("User", {})
	assert(mock.call == Call(context, Call.any_arg))

	mock:reset()
	context:disable()
	vim.api.nvim_exec_autocmds("User")
	assert_equals(mock.calls, {})
end

function Suite.bind_user_autocommand()
	local context = ContextHandler("ott")
	local mock = Mock()

	context.upgrade = mock
	context:bind_user_autocommand("upgrade")

	vim.api.nvim_exec_autocmds("User", { pattern = "OTTUpgrade" })
	assert_equals(mock.calls, {})

	context:enable()
	vim.api.nvim_exec_autocmds("User", { pattern = "OTTUpgrade" })
	assert(mock.call == Call(context, Call.any_arg))

	mock:reset()
	vim.api.nvim_exec_autocmds("User", { pattern = "OTTDowngrade" })
	assert_equals(mock.calls, {})

	context:disable()
	vim.api.nvim_exec_autocmds("User", { pattern = "OTTUpgrade" })
	assert_equals(mock.calls, {})
end

function Suite.execute_user_autocommand()
	local context = ContextHandler("ott")
	local mock = Mock()

	vim.api.nvim_create_autocmd("User", {
		pattern = "OTTUpgrade",
		callback = mock:as_function(),
	})

	context:execute_user_autocommand("upgrade")
	assert(mock.call == Call(Call.any_arg))
end

function Suite.add_user_command()
	local context = ContextHandler("ott")
	local mock = Mock()

	context.upgrade = mock
	context:bind_user_command("upgrade")

	assert(not pcall(function()
		vim.cmd(":OTTUpgrade")
	end))

	context:enable()
	vim.cmd(":OTTUpgrade")
	assert(mock.call == Call(context, Call.any_arg))

	context:disable()
	assert(not pcall(function()
		vim.cmd(":OTTUpgrade")
	end))
end
return Suite
