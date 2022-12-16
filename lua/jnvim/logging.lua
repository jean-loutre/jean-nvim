--- Module leveraging jlua.logging to provide logging functionnality in neovim.
local get_logger = require("jlua.logging").get_logger
local format = require("jlua.string").format

local Buffer = require("jnvim.buffer")

local logging = {}

function logging.open_log(logger_name)
	local logger = get_logger(logger_name)
	local buffer = Buffer({
		buftype = "nofile",
		filetype = "log",
		modifiable = false,
		name = format("nvim log : {}", logger_name),
	})

	local function handler(log_record)
		local log_message = format(log_record.format, log_record.args)
		local log_line = format("{} : {}", log_record.logger, log_message)
		buffer.modifiable = true
		buffer:append({ log_line })
		buffer.modifiable = false
	end

	logger:add_handler(handler)

	return buffer
end

return logging
