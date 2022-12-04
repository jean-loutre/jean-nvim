--- Object oriented Neovim buffer wrapper.
-- @module jnvim.buffer
local Object = require("jlua.object")
local Iterator = require("jlua.iterator")
local is_bool = require("jlua.type").is_bool
local is_number = require("jlua.type").is_number

local Buffer = Object:extend()

--- Initialize a buffer
--
-- @param buffer_handle The neovim buffer id.
function Buffer:init(list, scratch)
	list = list or false
	scratch = scratch or false

	assert(is_bool(list))
	assert(is_bool(scratch))

	self._handle = vim.api.nvim_create_buf(list, scratch)
end

--- Create a new buffer
--
-- @param buffer_handle The neovim buffer id.
function Buffer.from_handle(handle)
	assert(is_number(handle))
	return Buffer:wrap({
		_handle = handle,
	})
end

--- Retun an iterator existing nvim buffers.
--
-- @return A jlua.iterator of Buffer.
function Buffer.list()
	return Iterator.from_values(vim.api.nvim_list_bufs()):map(Buffer.from_handle)
end

function Buffer.properties.handle:get()
	return self._handle
end

function Buffer.properties.name:get()
	return vim.api.nvim_buf_get_name(self._handle)
end

function Buffer.properties.listed:get()
	return vim.bo[self._handle].buflisted
end

function Buffer.properties.listed:set(value)
	vim.bo[self._handle].buflisted = value
end

function Buffer.properties.name:set(value)
	return vim.api.nvim_buf_set_name(self._handle, value)
end

return Buffer