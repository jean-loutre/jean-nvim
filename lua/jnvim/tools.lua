--- Tools and user commands registerable.
local iter = require("jlua.iterator").iter
local get_logger = require("jlua.logging").get_logger

local UserCommand = require("jnvim.user-command")
local open_log = require("jnvim.logging").open_log

local log = get_logger(...)

local tools = {}

local user_commands = {
	JNOpenLog = {
		command = function(args)
			open_log(args.args)
		end,
		args = { nargs = "*" },
	},
}

function tools.load_commands(commands)
	for name in iter(commands) do
		local definition = user_commands[name]
		if not definition then
			log:warning(
				"trying to load unknown Jean-NVim user command : {}.",
				name
			)
		elseif not definition._instance then
			definition._instance =
				UserCommand(name, definition.command, definition.args)
		end
	end
end

return tools
