local Mock = require("jlua.mock")
local BoundContext = require("jnvim.bound-context")

local Suite = {}

function Suite.bind_function()
	vim.fn["ot#upgrade"] = function() end

	local context = BoundContext("ott")
	context.upgrade = Mock()
	context:bind_function("upgrade")

	assert_false(pcall(function()
		vim.fn["ott#upgrade"]("v2.0", "turbo-propulser")
	end))

	context:enable()
	vim.fn["ott#upgrade"]("v2.0", "turbo-propulser")
	assert_equals(context.upgrade.calls[1][1], context)
	assert_equals(context.upgrade.calls[1][2], "v2.0")
	assert_equals(context.upgrade.calls[1][3], "turbo-propulser")

	context:disable()

	assert_false(pcall(function()
		vim.fn["ott#upgrade"]("v2.0", "turbo-propulser")
	end))
end

function Suite.bind_autocommand()
	local context = BoundContext("ott")
	context.upgrade = Mock()
	context:bind_autocommand("User", "upgrade")

	vim.api.nvim_exec_autocmds("User", { data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls, {})

	context:enable()
	vim.api.nvim_exec_autocmds("User", { data = "v2.0:turbo-propulser" })
	assert_equals(#context.upgrade.calls, 1)
	assert_equals(context.upgrade.calls[1][1], context)
	assert_equals(context.upgrade.calls[1][2].data, "v2.0:turbo-propulser")

	context:disable()
	vim.api.nvim_exec_autocmds("User", { data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls[1][1], context)
	assert_equals(context.upgrade.calls[1][2].data, "v2.0:turbo-propulser")
	assert_is_nil(context.upgrade.calls[2])
end

function Suite.bind_user_autocommand()
	local context = BoundContext("ott")
	context.upgrade = Mock()
	context:bind_user_autocommand("upgrade")

	vim.api.nvim_exec_autocmds("User", { pattern = "OTTUpgrade", data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls, {})

	context:enable()
	vim.api.nvim_exec_autocmds("User", { pattern = "OTTUpgrade", data = "v2.0:turbo-propulser" })
	assert_equals(#context.upgrade.calls, 1)
	assert_equals(context.upgrade.calls[1][2].data, "v2.0:turbo-propulser")

	vim.api.nvim_exec_autocmds("User", { pattern = "OTTDowngrade", data = "v1.0:shitty-propulser" })
	assert_equals(#context.upgrade.calls, 1)
	assert_equals(context.upgrade.calls[1][2].data, "v2.0:turbo-propulser")

	context:disable()
	vim.api.nvim_exec_autocmds("User", { pattern = "OTTUpgrade", data = "v2.0:turbo-propulser" })
	assert_equals(context.upgrade.calls[1][2].data, "v2.0:turbo-propulser")
	assert_is_nil(context.upgrade.calls[2])
end

function Suite.execute_user_autocommand()
	local context = BoundContext("ott")
	local upgrade = Mock()
	vim.api.nvim_create_autocmd("User", {
		pattern = "OTTUpgrade",
		callback = upgrade:as_function(),
	})
	context:execute_user_autocommand("upgrade", "v2.0:turbo-propulser")
	assert_equals(#upgrade.calls, 1)
	assert_equals(upgrade.calls[1][1].data, "v2.0:turbo-propulser")
end

function Suite.add_user_command()
	local context = BoundContext("ott")
	context.upgrade = Mock()
	context:bind_user_command("upgrade")

	assert(not pcall(function()
		vim.cmd(":OTTUpgrade")
	end))

	context:enable()
	vim.cmd(":OTTUpgrade")
	assert_equals(#context.upgrade.calls, 1)

	context:disable()
	assert(not pcall(function()
		vim.cmd(":OTTUpgrade")
	end))
end
return Suite
