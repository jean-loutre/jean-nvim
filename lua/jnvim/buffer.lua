--- Object oriented wrapper around Neovim buffer.
---
--- This class provides only an OO convenience wrapper around the various lua
--- function that handle neovim buffers. No feature here, just another way to
--- call the nvim lua api.
---
--- @classmod jnvim.buffer.Buffer
local Object = require("jlua.object")
local iter = require("jlua.iterator").iter
local is_number = require("jlua.type").is_number

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

--- @function Buffer.properties.handle:get()
--- Numerical id this buffer wraps. See
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

--- Append lines to this buffer.
---
--- Wraps vim.api.nvim_buf_set_lines.
---
--- @usage
--- buffer:set_lines({"jean-jean", "jean-jean jacques"})
---
--- @tparam [string] lines The text line to append to the buffer.
--- @return jlua.iterator An iterator of buffer.
function Buffer:append(lines)
	vim.api.nvim_buf_set_lines(self._handle, -1, -1, 1, lines)
end

return Buffer
