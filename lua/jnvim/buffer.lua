--- Object oriented wrapper around Neovim buffer.
---
--- This class provides only an OO convenience wrapper around the various lua
--- function that handle neovim buffers. No feature here, just another way to
--- call the nvim lua api.
---
--- @classmod jnvim.buffer.Buffer
local List = require("jlua.list")
local Object = require("jlua.object")
local context_manager = require("jlua.context").context_manager
local is_number = require("jlua.type").is_number
local iter = require("jlua.iterator").iter

local Namespace = require("jnvim.namespace")
local Range = require("jnvim.range")

--- @class jnvim.Buffer
local Buffer = Object:extend()

---
--- Options should be a table of options to set on this buffer. It can be any
--- [buffer options ](https://neovim.io/doc/user/options.html#option-summary)
--- or jnvim.buffer.Buffer property. (For example, you can set a name key, and
--- the buffer name will be set through the jnvim.buffer.Buffer.name property).
---
--- @usage
--- local buffer = Buffer({
---     name = "otter list",
---     listed = false,
---     modifiable = false
--- })
---
--- @tparam[opt={}] table[any] options Buffer options.
function Buffer:init(options)
	options = options or {}
	self._handle = vim.api.nvim_create_buf(true, true)

	for option, value in iter(options) do
		self[option] = value
	end
end

--- Wraps a neovim buffer.
---
--- Create an instance of jnvim.buffer.Buffer that wraps the existing buffer
--- with the given handle (buf).
---
--- @usage
--- local buffer = Buffer.wrap(vim.api.nvim_get_current_buf())
---
--- @tparam number handle Numerical buffer id.
function Buffer.from_handle(handle)
	assert(is_number(handle))
	return Buffer:wrap({
		_handle = handle,
	})
end

--- @function Buffer.properties.lines:get()
--
--- @return number
function Buffer.properties.handle:get()
	return self._handle
end

--- @function Buffer.properties.name:get()
--- Name of the buffer.
--- Wraps vim.api.nvim_buf_get_name and vim.api.nvim_buf_set_name.
--- @return string
function Buffer.properties.name:get()
	return vim.api.nvim_buf_get_name(self._handle)
end

--- @function Buffer.properties.name:set()
function Buffer.properties.name:set(value)
	return vim.api.nvim_buf_set_name(self._handle, value)
end

--- @function Buffer.properties.___.get()
--- Get or set an option for this buffer. Wraps
--- [vim.bo](https://neovim.io/doc/user/lua.html#vim.bo). See
--- [the nvim documentation](https://neovim.io/doc/user/options.html#option-summary)
--- for a list of available options.
---
--- @usage
--- local is_listed = buffer.listed
--- buffer.listed = false
---
--- @return any Option value.
function Buffer:__index(key)
	return vim.bo[self._handle][key]
end

--- @function Buffer.properties.___.set()
function Buffer:__newindex(key, value)
	if key == "_handle" then
		rawset(self, key, value)
	else
		vim.bo[self._handle][key] = value
	end
end

--- Return an iterator existing nvim buffers.
---
--- Wraps vim.api.nvim_list_bufs.
---
--- @usage
--- for buffer in Buffer.list() do
---     buffer:delete()
--- end
---
--- @return jlua.iterator An iterator of buffer.
function Buffer.list()
	return iter(vim.api.nvim_list_bufs()):map(Buffer.from_handle)
end

--- @function Buffer:edit
---
--- Context manager getting a jnvim.range.Range over the whole buffer as
--- context argument.
---
--- If the buffer has the option modifiable = false, it will be
--- automatically set to true in the context, and reset to false when the
--- context is exited.
---
--- See jnvim.range.Range for the why of a context manager here.
Buffer.edit = context_manager(function(self)
	local bounds_namespace = Namespace()
	local line_count = vim.api.nvim_buf_line_count(self._handle)
	local range = Range(self, bounds_namespace, 0, 0, line_count - 1, -1)

	local modifiable = self.modifiable
	if not modifiable then
		self.modifiable = true
	end

	coroutine.yield(range)

	if not modifiable then
		self.modifiable = false
	end

	range:clear_namespace(bounds_namespace)
end)

--- Get the text lines of the buffer.
---
--- See vim.api.nvim_buf_get_lines. By default, return all the lines of the
--- buffer.
---
--- @usage
--- buffer:get_lines(2, -2)
--- -- Get the lines from the second to the second before the end.
---
--- @tparam[opt=0] number start The starting line.
--- @tparam[opt=-1] number end_  The ending line.
--- @return jlua.list A list of string.
function Buffer:get_lines(start, end_)
	start = start or 0
	end_ = end_ or -1
	return List(vim.api.nvim_buf_get_lines(self._handle, start, end_, true))
end

--- Replaces text in a buffer.
---
--- Wraps vim.api.nvim_buf_set_lines. If start and end_ are not provided, the
--- lines are appended to the buffer.
---
--- @usage
--- buffer:set_lines({"jean-jean", "jean-jean jacques"})
---
--- @tparam [string] lines The text line to append to the buffer.
--- @tparam[opt=-1] number start The starting line.
--- @tparam[opt=-1] number end_  The ending line.
--- @return jlua.iterator An iterator of buffer.
function Buffer:set_lines(lines, start, end_)
	start = start or -1
	end_ = end_ or -1
	vim.api.nvim_buf_set_lines(self._handle, start, end_, 1, lines)
end

--- Delete a buffer.
---
--- Wraps vim.api.nvim_buf_delete. See this link for more informations about
--- the options.
---
--- @usage
--- buffer:delete({force = true})
---
--- @tparam[opt={}] [table] options Delete options
function Buffer:delete(options)
	options = options or {}
	vim.api.nvim_buf_delete(self._handle, options)
end

return Buffer
