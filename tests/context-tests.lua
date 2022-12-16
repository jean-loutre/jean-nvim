local Buffer = require("jnvim.buffer")
local Call = require("jlua.test.call")
local Mock = require("jlua.test.mock")
local Context = require("jnvim.context")

local Suite = {}

function Suite.add_function()
	local function tickle_otter_tail() end
	local function tickle_otter_nose() end

	vim.fn.tickle_otter = tickle_otter_tail

	local context = Context()

	context:add_function("tickle_otter", tickle_otter_nose)
	assert_equals(vim.fn.tickle_otter, tickle_otter_tail)

	context:enable()
	assert_equals(vim.fn.tickle_otter, tickle_otter_nose)

	context:disable()
	assert_equals(vim.fn.tickle_otter, tickle_otter_tail)
end

function Suite.add_autocommand()
	local otter_said = "nothing"
	local function tickle_otter(args)
		assert(Buffer:is_class_of(args.buf))
		otter_said = "Kweek kweek"
	end

	local context = Context()

	context:add_autocommand(
		"User",
		{ callback = tickle_otter, pattern = "Tickle" }
	)
	vim.api.nvim_exec_autocmds("User", { pattern = "Tickle" })
	assert_equals(otter_said, "nothing")

	context:enable()
	vim.api.nvim_exec_autocmds("User", { pattern = "Tickle" })
	assert_equals(otter_said, "Kweek kweek")
	otter_said = "nothing"

	context:disable()
	vim.api.nvim_exec_autocmds("User", { pattern = "Tickle" })
	assert_equals(otter_said, "nothing")
end

function Suite.add_user_command()
	local mock = Mock()
	local context = Context()

	context:add_user_command("TickleOtter", mock:as_function())
	assert(not pcall(function()
		vim.cmd(":TickleOtter")
	end))

	context:enable()
	vim.cmd(":TickleOtter")
	assert(mock.call, { Call.any_arg })

	context:disable()
	assert(not pcall(function()
		vim.cmd(":TickleOtter")
	end))
end

return Suite
