local Buffer = require("gilbert.nvim.buffer")
local TestSuite = require("gilbert.nvim.test-suite")

local Suite = TestSuite()

function Suite.create()
	local buffer = Buffer.create()
	assert_not_equals(buffer.handle, 0)
end

function Suite.list()
	local buffer_list = Buffer.list():to_list()
	assert_equals(#buffer_list, 1)

	local new_buffer = Buffer.create()
	buffer_list = Buffer.list():to_list()
	assert_equals(#buffer_list, 2)
	assert_equals(new_buffer.handle, buffer_list[2].handle)
end

function Suite.handle()
	local buffer = Buffer(10)
	assert_equals(buffer.handle, 10)
end

function Suite.name()
	vim.api.nvim_command("enew")
	local buffer_handle = vim.api.nvim_get_current_buf()
	local buffer = Buffer(buffer_handle)

	vim.api.nvim_buf_set_name(buffer_handle, "peter")
	assert_equals(buffer.name, vim.fn.getcwd() .. "/peter")

	buffer.name = "steven"
	assert_equals(vim.api.nvim_buf_get_name(buffer_handle), vim.fn.getcwd() .. "/steven")
end

return Suite