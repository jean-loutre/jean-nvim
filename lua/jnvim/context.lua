--- Handle vim user commands, autocommands, mappings and functions registration.
--
-- Vim mappings, autocommands, user commands and functions are registered
-- in a context, then this context can be enabled to effectively enable those,
-- and disabled, to restore previous state.
--
-- @module jnvim.context
local List = require("jlua.list")
local Map = require("jlua.map")
local Object = require("jlua.object")
local is_callable = require("jlua.type").is_callable
local is_string = require("jlua.type").is_string
local iter = require("jlua.iterator").iter

local Autocommand = require("jnvim.autocommand")
local UserCommand = require("jnvim.user-command")

local Context = Object:extend()

--- Initialize a context
function Context:init()
	self._enabled = false
	self._functions = Map()
	self._autocommands = List()
	self._saved_functions = Map()
	self._user_commands = List()
	self._mappings = List()
end

--- Register a function in the context.
--
-- The given function will be callable through vim.fn[name] when the context
-- is enabled.
--
--  @param name     Name of the function to register.
--  @param callback Function to register.
--
--  @return self, to allow chaining calls
function Context:add_function(name, callback)
	assert(is_string(name))
	assert(is_callable(callback))
	assert(not self._enabled)
	self._functions[name] = callback
	return self
end

--- Register an autocommand in the context.
--
-- The given autocommand will be called when the context is enabled.
--
-- The given parameters are those taken by nvim_create_autocommand. For
-- example, to call a lua function each time a python file is open, use :
-- ```
-- context:add_autocommand("BufAdd", {
-- 	   pattern = "*.py",
-- 	   callback = function(args)
-- 	       print("New python buffer : " .. args.file)
-- 	   end
-- })
--
--  @param events   The event or events to register this autocommand.
--  @param options  Options to pass to nvim_create_autocommand.
--
--  @return self, to allow chaining calls
function Context:add_autocommand(events, options)
	self._autocommands:push({
		events = events,
		options = options,
	})
	return self
end

--- Register an user command in the context.
--
-- The given user command will be callable when the context is enabled.
function Context:add_user_command(name, callback, options, buffer)
	self._user_commands:push({
		name = name,
		callback = callback,
		options = options,
		buffer = buffer,
	})
	return self
end

--- Register a key mapping into the context
function Context:map(mode, lhs, rhs, options)
	self._mappings:push({
		mode = mode,
		lhs = lhs,
		rhs = rhs,
		options = options,
	})
	return self
end

--- Enable the context
--
-- Actually enable all registered commands, mappings etc. in vim and save the
-- current state.
function Context:enable()
	assert(not self._enabled)
	for name, func in self._functions:iter() do
		self._saved_functions[name] = vim.fn[name]
		vim.fn[name] = func
	end

	for command in self._autocommands:iter() do
		assert(command.instance == nil)
		command.instance = Autocommand(command.events, command.options)
	end

	for it in self._user_commands:iter() do
		assert(it.instance == nil)
		it.instance = UserCommand(it.name, it.callback, it.options, it.buffer)
	end

	for mapping in self._mappings:iter() do
		local mode = mapping.mode
		local lhs = mapping.lhs
		local rhs = mapping.rhs
		local options = mapping.options
		local old_mapping = vim.fn["maparg"](lhs, mode, 0, 1)
		mapping.old_mapping = old_mapping
		vim.api.nvim_set_keymap(mode, lhs, rhs, options)
	end

	self._enabled = true
end

--- Disable the context
--
-- Disable all registered commands, mappings, etc. in vim and restore the
-- previous state.
function Context:disable()
	for mapping in self._mappings:iter() do
		local old_mapping = mapping.old_mapping
		if iter(old_mapping):any() then
			vim.fn["mapset"](mapping.mode, 0, old_mapping)
		else
			vim.api.nvim_del_keymap(mapping.mode, mapping.lhs)
		end
	end

	assert(self._enabled)
	for it in self._user_commands:iter() do
		assert(it.instance)
		it.instance:delete()
		it.instance = nil
	end

	for command in self._autocommands:iter() do
		assert(command.instance)
		command.instance:delete()
		command.instance = nil
	end

	for name, func in self._functions:iter() do
		assert(vim.fn[name] == func)
		vim.fn[name] = self._saved_functions[name]
	end
	self._enabled = false
end

return Context
