--- Object-oriented [extmarks](https://neovim.io/doc/user/api.html#extmarks)
---
--- Extmark object wrapper can be constructed from jnvim.range.Range objects.
---
--- @classmod jnvim.range.Extmark
local Object = require("jlua.object")

--- @class jnvim.range.Extmark
local Extmark = Object:extend()

--- Use jnvim.range.Range.add_mark to create a mark.
--- @private
function Extmark:init(buffer, namespace, row, col, options)
	options = options or {}
	self._buffer = buffer
	self._namespace = namespace
	self._id = vim.api.nvim_buf_set_extmark(
		self._buffer.handle,
		self._namespace.id,
		row,
		col,
		options
	)
end

--- @function Extmark.properties.position:get()
--- Get / set the position of this mark, as a table with a row and a col keys.
--- @treturn {row:number,col:number} end position.
function Extmark.properties.position:get()
	local bounds = vim.api.nvim_buf_get_extmark_by_id(
		self._buffer.handle,
		self._namespace.id,
		self._id,
		{}
	)

	return {
		row = bounds[1],
		col = bounds[2],
	}
end

--- @function Extmark.properties.position:set()
function Extmark.properties.position:set(value)
	self._id = vim.api.nvim_buf_set_extmark(
		self._buffer.handle,
		self._namespace.id,
		value.row,
		value.col,
		{}
	)
end

return Extmark
