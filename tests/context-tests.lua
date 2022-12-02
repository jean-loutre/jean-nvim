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
	local function tickle_otter()
		otter_said = "kweekweekweek"
	end

	local context = Context()

	context:add_autocommand("User", { callback = tickle_otter, pattern = "Tickle" })
	vim.api.nvim_exec_autocmds("User", { pattern = "Tickle" })
	assert_equals(otter_said, "nothing")

	context:enable()
	vim.api.nvim_exec_autocmds("User", { pattern = "Tickle" })
	assert_equals(otter_said, "kweekweekweek")
	otter_said = "nothing"

	context:disable()
	vim.api.nvim_exec_autocmds("User", { pattern = "Tickle" })
	assert_equals(otter_said, "nothing")
end

return Suite
