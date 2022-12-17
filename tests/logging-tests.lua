local create_log_buffer = require("jnvim.logging").create_log_buffer
local get_logger = require("jlua.logging").get_logger

local Suite = {}

function Suite.log()
	local logger = get_logger("jean.paul")
	local log_buffer = create_log_buffer("jean.paul")
	logger:warning("hello there")
	assert_equals(log_buffer:get_lines(), { "WARNING:jean.paul:hello there" })

	log_buffer:delete()
	logger:warning("It shouldn't raise an error.")
end

function Suite.set_level()
	local logger = get_logger("jean.paul")
	local log_buffer = create_log_buffer("jean.paul")
	logger:debug("hello there")
	assert_equals(log_buffer:get_lines(), { "" })

	vim.api.nvim_win_set_buf(0, log_buffer.handle)
	vim.cmd("JNSetLevel debug")
	logger:debug("hello there")
	assert_equals(log_buffer:get_lines(), { "DEBUG:jean.paul:hello there" })
end

return Suite
