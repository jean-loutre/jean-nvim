--- Object oriented Neovim buffer wrapper.
-- @module gilbert.nvim.buffer
local Object = require("gilbert.object")
local Iterator = require("gilbert.iterator")
local is_bool = require("gilbert.type").is_bool
local is_number = require("gilbert.type").is_number

local Buffer = Object:extend()

--- Initialize a buffer
--
-- @param buffer_handle The neovim buffer id.
function Buffer:init(buffer_handle)
	assert(is_number(buffer_handle))
	self._buffer_handle = buffer_handle
end

--- Create a new buffer
--
-- @param buffer_handle The neovim buffer id.
function Buffer.create(list, scratch)
	list = list or false
	scratch = scratch or false

	assert(is_bool(list))
	assert(is_bool(scratch))

	local handle = vim.api.nvim_create_buf(list, scratch)
	return Buffer(handle)
end

--- Retun an iterator existing nvim buffers.
--
-- @return A gilbert.iterator of Buffer.
function Buffer.list()
	return Iterator.from_values(vim.api.nvim_list_bufs()):map(Buffer)
end

function Buffer.properties.handle:get()
	return self._buffer_handle
end

function Buffer.properties.name:get()
	return vim.api.nvim_buf_get_name(self._buffer_handle)
end

function Buffer.properties.listed:get()
	return vim.bo[self._buffer_handle].buflisted
end

function Buffer.properties.listed:set(value)
	vim.bo[self._buffer_handle].buflisted = value
end

function Buffer.properties.name:set(value)
	return vim.api.nvim_buf_set_name(self._buffer_handle, value)
end

return Buffer
