--- Object oriented wrapper around Neovim buffer.
---
-- @classmod jnvim.buffer
local Object = require("jlua.object")
local iter = require("jlua.iterator").iter
local is_bool = require("jlua.type").is_bool
local is_number = require("jlua.type").is_number

--- @class jnvim.Buffer:jlua.Object
local Buffer = Object:extend()

--- Initialize a buffer
--
-- @param buffer_handle The neovim buffer id.
function Buffer:init(options)
	options = options or {}
	self._handle = vim.api.nvim_create_buf(true, true)

	for option, value in iter(options) do
		self[option] = value
	end
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

--- Get the option associated with this buffer
--- @param key string The option name
function Buffer:__index(key)
	return vim.bo[self._handle][key]
end

--- Set the option associated with this buffer.
--- @param key string The option name.
--- @param value any The option value.
function Buffer:__newindex(key, value)
	if key == "_handle" then
		rawset(self, key, value)
	else
		vim.bo[self._handle][key] = value
	end
end

--- Retun an iterator existing nvim buffers.
--
-- @return A jlua.iterator of Buffer.
function Buffer.list()
	return iter(vim.api.nvim_list_bufs()):map(Buffer.from_handle)
end

function Buffer.properties.handle:get()
	return self._handle
end

function Buffer.properties.name:get()
	return vim.api.nvim_buf_get_name(self._handle)
end

function Buffer.properties.name:set(value)
	return vim.api.nvim_buf_set_name(self._handle, value)
end

function Buffer:append(lines)
	vim.api.nvim_buf_set_lines(self._handle, -1, -1, 1, lines)
end

return Buffer
