--- Wrapper around autocommand wrapping callbacks arguments in jlua / jnvim
-- wrappers
local Object = require("jlua.object")

--- Object-oriented wrapper around nvim user command
local UserCommand = Object:extend()

--- Initialize the user command
--
-- Parameters
-- ----------
-- @param name: name of the autocommand group.
-- @param clear: clear the group on creation.
function UserCommand:init(name, command, options)
	self._name = name
	vim.api.nvim_create_user_command(name, command, options or {})
end

--- Delete the user command
function UserCommand:delete()
	vim.api.nvim_del_user_command(self._name)
end

return UserCommand
