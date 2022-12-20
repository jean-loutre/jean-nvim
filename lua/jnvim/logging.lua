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

local LogBuffer = Object:extend()

function LogBuffer:init(logger_name)
	self._name = logger_name

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

	local log_message = format(record.format, record.args)
	local log_level = get_level_string(record.level)
	local log_line = format("{}:{}:{}", log_level, record.logger, log_message)
	with(self._buffer:edit(), function(buffer)
		buffer:insert({ log_line, "" })
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

return logging
