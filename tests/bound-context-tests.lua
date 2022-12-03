local Mock = require("jlua.mock")
local BoundContext = require("jnvim.bound-context")

local Suite = {}

function Suite.bind_function()
	vim.fn.otters_upgrade = function() end

	local context = BoundContext("otters_")
	context.upgrade = Mock()
	context:bind_function("upgrade")

	vim.fn.otters_upgrade("v2.0", "turbo-propulser")
	assert_equals(context.upgrade.calls, {})

	context:enable()
	vim.fn.otters_upgrade("v2.0", "turbo-propulser")
	assert_equals(context.upgrade.calls, { { "v2.0", "turbo-propulser" } })

	context:disable()
	vim.fn.otters_upgrade("v2.0", "turbo-propulser")
	assert_equals(context.upgrade.calls, { { "v2.0", "turbo-propulser" } })
end

function Suite.bind_autocommand()
	local context = BoundContext("otters_")
	context.upgrade = Mock()
	context:bind_autocommand("User", "upgrade")

	vim.api.nvim_exec_autocmds("User", { data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls, {})

	context:enable()
	vim.api.nvim_exec_autocmds("User", { data = "v2.0:turbo-propulser" })
	assert_equals(#context.upgrade.calls, 1)
	assert_equals(context.upgrade.calls[1][1].data, "v2.0:turbo-propulser")

	context:disable()
	vim.api.nvim_exec_autocmds("User", { data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls[1][1].data, "v2.0:turbo-propulser")
	assert_is_nil(context.upgrade.calls[2])
end

function Suite.bind_user_autocommand()
	local context = BoundContext("otters_")
	context.upgrade = Mock()
	context:bind_user_autocommand("upgrade")

	vim.api.nvim_exec_autocmds("User", { pattern = "otters_upgrade", data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls, {})

	context:enable()
	vim.api.nvim_exec_autocmds("User", { pattern = "otters_upgrade", data = "v2.0:turbo-propulser" })
	assert_equals(#context.upgrade.calls, 1)
	assert_equals(context.upgrade.calls[1][1].data, "v2.0:turbo-propulser")

	vim.api.nvim_exec_autocmds("User", { pattern = "otters_downgrade", data = "v1.0:shitty-propulser" })
	assert_equals(#context.upgrade.calls, 1)
	assert_equals(context.upgrade.calls[1][1].data, "v2.0:turbo-propulser")

	context:disable()
	vim.api.nvim_exec_autocmds("User", { pattern = "otters_upgrade", data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls[1][1].data, "v2.0:turbo-propulser")
	assert_is_nil(context.upgrade.calls[2])
end

return Suite
