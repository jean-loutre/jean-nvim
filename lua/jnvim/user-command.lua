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
function UserCommand:init(name, command, options, buffer)
	self._name = name
	self._buffer = buffer
	if not self._buffer then
		vim.api.nvim_create_user_command(name, command, options or {})
	else
		vim.api.nvim_buf_create_user_command(
			self._buffer.handle,
			name,
			command,
			options or {}
		)
	end
end

--- Delete the user command
function UserCommand:delete()
	if not self._buffer then
		vim.api.nvim_del_user_command(self._name)
	else
		vim.api.nvim_buf_del_user_command(self._buffer.handle, self._name)
	end
end

return UserCommand
