--- Module leveraging jlua.logging to provide logging functionnality in neovim.
local LOG_LEVEL = require("jlua.logging").LOG_LEVEL
local Object = require("jlua.object")
local bind = require("jlua.functional").bind
local format = require("jlua.string").format
local get_level_string = require("jlua.logging").get_level_string
local get_logger = require("jlua.logging").get_logger
local with = require("jlua.context").with

local Buffer = require("jnvim.buffer")
local Context = require("jnvim.context")
local Namespace = require("jnvim.namespace")

local unpack = unpack or table.unpack

local LogBuffer = Object:extend()

local function set_highlight(name, link)
	vim.api.nvim_set_hl(0, name, { link = link, default = true })
end

set_highlight("LogDebug", "DiagnosticHint")
set_highlight("LogInfo", "DiagnosticInfo")
set_highlight("LogWarning", "DiagnosticWarn")
set_highlight("LogError", "DiagnosticError")
set_highlight("LogCritical", "Error")

local function get_level_highlight(level)
	if level == LOG_LEVEL.DEBUG then
		return "LogDebug"
	elseif level == LOG_LEVEL.INFO then
		return "LogInfo"
	elseif level == LOG_LEVEL.WARNING then
		return "LogWarning"
	elseif level == LOG_LEVEL.ERROR then
		return "LogError"
	end

	return "LogCritical"
end

function LogBuffer:init(logger_name)
	self._name = logger_name
	self._highlight_namespace = Namespace()

	self._buffer = Buffer({
		buftype = "nofile",
		filetype = "log",
		modifiable = false,
		name = format("log[{}]", self._name),
	})

	self._level = LOG_LEVEL.INFO
	self._handler = bind(self._handle, self)
	get_logger(self._name):add_handler(self._handler)

	self._context = Context()
	self._context:add_autocommand(
		"BufDelete",
		{ callback = bind(self._on_delete, self), buffer = self._buffer.handle }
	)
	self._context:add_user_command(
		"JNSetLevel",
		bind(self._set_level, self),
		{ nargs = 1 },
		self._buffer
	)
	self._context:enable()
end

function LogBuffer.properties.buffer:get()
	return self._buffer
end

function LogBuffer:_handle(record)
	if self._level > record.level then
		return
	end

	local log_message = format(record.format, unpack(record.args))
	local log_level = get_level_string(record.level)
	with(self._buffer:edit(), function(buffer)
		for message_line in log_message:gmatch("[^\r\n]+") do
			local log_line = format("{}:{}:{}", log_level, record.logger, message_line)
			local line_range = buffer:insert({ log_line, "" })
			line_range:set_extmark(self._highlight_namespace, 0, 0, {
				end_row = -1,
				end_col = -1,
				hl_group = get_level_highlight(record.level),
			})
		end
	end)
end

function LogBuffer:_set_level(args)
	self._level = LOG_LEVEL[args.args:upper()] or LOG_LEVEL.INFO
end

function LogBuffer:_on_delete()
	get_logger(self._name):remove_handler(self._handler)
	self._context:disable()
end

local logging = {}

function logging.create_log_buffer(logger_name)
	return LogBuffer(logger_name).buffer
end

function logging.open_log(logger_name)
	local buffer = logging.create_log_buffer(logger_name)
	vim.api.nvim_win_set_buf(0, buffer.handle)
end

return logging
