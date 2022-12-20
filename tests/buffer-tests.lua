local Buffer = require("jnvim.buffer")
local Range = require("jnvim.range")
local with = require("jlua.context").with

local TestSuite = require("jnvim.test-suite")

local Suite = TestSuite()

function Suite.create()
	local buffer = Buffer()
	assert_not_equals(buffer.handle, 0)
end

function Suite.property_handle()
	local buffer = Buffer.from_handle(10)
	assert_equals(buffer.handle, 10)
end

function Suite.property_name()
	vim.api.nvim_command("enew")
	local buffer_handle = vim.api.nvim_get_current_buf()
	local buffer = Buffer.from_handle(buffer_handle)

	vim.api.nvim_buf_set_name(buffer_handle, "peter")
	assert_equals(buffer.name, vim.fn.getcwd() .. "/peter")

	buffer.name = "steven"
	assert_equals(
		vim.api.nvim_buf_get_name(buffer_handle),
		vim.fn.getcwd() .. "/steven"
	)
end

function Suite.list()
	local buffer_list = Buffer.list():to_list()
	assert_equals(#buffer_list, 1)

	local new_buffer = Buffer()
	buffer_list = Buffer.list():to_list()
	assert_equals(#buffer_list, 2)
	assert_equals(new_buffer.handle, buffer_list[2].handle)
end

function Suite.edit()
	local buffer = Buffer()
	vim.api.nvim_buf_set_text(
		buffer.handle,
		0,
		0,
		0,
		0,
		{ "i", "have", "4", "lines" }
	)
	with(buffer:edit(), function(range)
		assert(Range:is_class_of(range))
		local buffer_text = vim.api.nvim_buf_get_text(
			buffer.handle,
			range.start.row,
			range.start.col,
			range.end_.row,
			range.end_.col,
			{}
		)
		assert_equals(buffer_text, { "i", "have", "4", "lines" })
	end)
end

return Suite
