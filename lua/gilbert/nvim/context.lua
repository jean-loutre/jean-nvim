--- Handle vim user commands, autocommands, mappings and functions registration.
--
-- Vim mappings, autocommands, user commands and functions are registered
-- in a context, then this context can be enabled to effectively enable those,
-- and disabled, to restore previous state.
--
-- @module gilbert.nvim.context
local List = require("gilbert.list")
local Map = require("gilbert.map")
local Object = require("gilbert.object")
local is_callable = require("gilbert.type").is_callable
local is_number = require("gilbert.type").is_number
local is_string = require("gilbert.type").is_string

local Context = Object:extend()

--- Initialize a context
function Context:init()
	self._enabled = false
	self._functions = Map()
	self._autocommands = List()
	self._saved_functions = Map()
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
		assert(command.id == nil)
		command.id = vim.api.nvim_create_autocmd(command.events, command.options)
	end

	self._enabled = true
end

--- Disable the context
--
-- Disable all registered commands, mappings, etc. in vim and restore the
-- previous state.
function Context:disable()
	assert(self._enabled)

	for command in self._autocommands:iter() do
		assert(is_number(command.id))
		vim.api.nvim_del_autocmd(command.id)
		command.id = nil
	end

	for name, func in self._functions:iter() do
		assert(vim.fn[name] == func)
		vim.fn[name] = self._saved_functions[name]
	end
	self._enabled = false
end

return Context
