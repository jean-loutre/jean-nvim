--- Range is the entry point to modify buffer content, higlights, virtual-text...
---
--- To create a new range, use jnvim.buffer.Buffer.edit method of
--- jnvim.buffer.Buffer:
---
--- ```lua
--- local with = require("jlua.context").with
---
--- local buffer = Buffer()
--- with(buffer:edit(), function(buffer_range)
--- 	buffer_range:set_text({"hello", "world"})
--- end)
--- ```
---
--- Range uses extmarks to mark the start and end of the pointed area. This
--- means that if you insert or delete text inside a range by any means, the
--- range boundaries will be updated accordingly. This explains the use of a
--- context manager : the marks at the range boundaries are cleared when the
--- edit context is exited.
---
--- @classmod jnvim.range.Range
local Object = require("jlua.object")

--- @class jnvim.range.Range
local Range = Object:extend()

--- @private
--- Do not create ranges directly : use buffer edit() context manager to be
--- sure no marks are leaked out when constructing range instances.
function Range:init(
	buffer,
	bounds_namespace,
	start_row,
	start_col,
	end_row,
	end_col
)
	assert(start_row >= 0)
	assert(end_row >= 0)
	self._buffer = buffer
	self._bounds_namespace = bounds_namespace

	self._start_mark_id = vim.api.nvim_buf_set_extmark(
		buffer.handle,
		bounds_namespace.id,
		start_row,
		start_col,
		{}
	)

	self._end_mark_id = vim.api.nvim_buf_set_extmark(
		buffer.handle,
		bounds_namespace.id,
		end_row,
		end_col,
		{}
	)
end

--- @function Range.properties.start:get()
--- Get the start position of this range, as a (row, col) tuple.
--- @treturn (number,number) (row, col) start position.
function Range.properties.start:get()
	local bounds = vim.api.nvim_buf_get_extmark_by_id(
		self._buffer.handle,
		self._bounds_namespace.id,
		self._start_mark_id,
		{}
	)
	return {
		row = bounds[1],
		col = bounds[2],
	}
end

--- @function Range.properties.end_:get()
--- Get the end position of this range, as a (row, col) tuple.
--- @treturn (number,number) (row, col) end position.
function Range.properties.end_:get()
	local bounds = vim.api.nvim_buf_get_extmark_by_id(
		self._buffer.handle,
		self._bounds_namespace.id,
		self._end_mark_id,
		{}
	)

	return {
		row = bounds[1],
		col = bounds[2],
	}
end

--- @function Range.properties.text:get()
--- Get the lines of text in this range
--- @treturn {string} Lines in this range
function Range.properties.text:get()
	local start = self.start
	local end_ = self.end_
	return vim.api.nvim_buf_get_text(
		self._buffer.handle,
		start.row,
		start.col,
		end_.row,
		end_.col,
		{}
	)
end

--- @function Range.properties.text:set()
function Range.properties.text:set(lines)
	local start = self.start
	local end_ = self.end_
	vim.api.nvim_buf_set_text(
		self._buffer.handle,
		start.row,
		start.col,
		end_.row,
		end_.col,
		lines
	)

	vim.api.nvim_buf_set_extmark(
		self._buffer.handle,
		self._bounds_namespace.id,
		start.row,
		start.col,
		{ id = self._start_mark_id }
	)
end

--- Clears a namespace in the pointed buffer's range area.
--- @tparam jnvim.namespace.Namespace namespace Namespace to clear.
function Range:clear_namespace(namespace)
	vim.api.nvim_buf_clear_namespace(
		self._buffer.handle,
		namespace.id,
		self.start.row,
		self.end_.row
	)
end

--- Insert lines at the given position, relative to the range boundaries.
---
--- row and col are 0-indexed. If row is negative, it will be interpreted
--- as relative to the range end boundary. If no row or col is provided,
--- the content will be inserted at the end of this range.
--
--- @tparam content {string} Table of lines to insert.
--- @tparam[opt=-1] number row Insert row, relative to this range.
--- @tparam[opt=-1] number col Insert col, relative to this range.
--- @return jnvim.range.Range Range covering the inserted content.
function Range:insert(content, row, col)
	row = row or -1
	col = col or -1

	local start = self.start
	local end_ = self.end_

	if row < 0 then
		row = end_.row + row + 1
	else
		row = start.row + row
	end

	if row == start.row and col > 0 then
		col = start.col + col
	elseif row == end_.row and col < 0 then
		col = end_.col + col + 1
	elseif col < 0 then
		local line = vim.api.nvim_buf_get_lines(
			self._buffer.handle,
			row,
			row + 1,
			true
		)[1]
		col = col + #line
	end

	local range =
		Range(self._buffer, self._bounds_namespace, row, col, row, col)
	range.text = content

	vim.api.nvim_buf_set_extmark(
		self._buffer.handle,
		self._bounds_namespace.id,
		start.row,
		start.col,
		{ id = self._start_mark_id }
	)

	return range
end

return Range
