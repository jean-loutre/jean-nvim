--- Wrapper around context that can be inherited to ease autocommands and
-- function registration
--
-- @module jnvim.bound-context
local Object = require("jlua.object")
local Context = require("jnvim.context")

local BoundContext = Object:extend()

--- Initialize a BoundContext.
--
-- Parameters
-- ----------
-- namespace : str, optional
--     The namespace for this bound context. It is prepended to all registered
--     functions. If not previded, no namespace will be prepended to the function
--     names.
function BoundContext:init(namespace)
	self._namespace = namespace or ""
	self._wrapped = Context()
end

--- Enable this context
function BoundContext:enable()
	self._wrapped:enable()
end

--- Disable this context
function BoundContext:disable()
	self._wrapped:disable()
end

--- Register a methood on self as a callback for a vim function
--
-- Parameters
-- ----------
-- name : str
--     Register a vim function with the name {self._namespace}{name}, bound to
--     self[name].
function BoundContext:bind_function(name)
	assert(self[name] ~= nil)
	self._wrapped:add_function(self._namespace .. name, function(...)
		self[name](...)
	end)
end

--- Register an autocommand for a method on self
--
-- Parameters
-- ----------
-- event : str
--     Event to register the autocommand.
-- name : str
--     Name of the method to call on self when the autocommand is executed
-- options: {str=*}
--     Options to forward to Autocommand
function BoundContext:bind_autocommand(event, name, options)
	assert(self[name] ~= nil)
	options = options or {}
	options.callback = function(args)
		self[name](args)
	end
	self._wrapped:add_autocommand(event, options)
end

--- Register a user autocommand for a method on self
--
-- This will bind the command with the pattern {self._namespace}{name}, to allow
-- easy filtering of user commands.
--
-- Parameters
-- ----------
-- name : str
--     Name of the method to call on self when the autocommand is executed with
--     the pattern {self._namespace}{name}
-- options: {str=*}
--     Options to forward to Autocommand
function BoundContext:bind_user_autocommand(name, options)
	options = options or {}
	options.pattern = self._namespace .. name
	self:bind_autocommand("User", name, options)
end

--- Execute an user autocommand
--
-- This will set the pattern to {self._namespace}{name}.
--
-- Parameters
-- ----------
-- name : str
--     Name of the autocommand to execute
-- data : *
--     Data to pass to executed autocommands
function BoundContext:execute_user_autocommand(name, data)
	vim.api.nvim_exec_autocmds("User", {
		pattern = self._namespace .. name,
		data = data,
	})
end

return BoundContext
