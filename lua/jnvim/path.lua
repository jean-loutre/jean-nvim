--- Gilbert Path augmentation with filesystem access from vim.
-- @module jnvim.path
local iter = require("jlua.iterator").iter
local List = require("jlua.list")
local Path = require("jlua.path")

--- Return a Path to the current working directory.
--
-- Will return the working directory for the current window and tab.
--
-- @return a jlua.path of the current working directory.
function Path.cwd()
	return Path(vim.fn.getcwd())
end

--- Return an iterator over the children of this path.
--
-- @return A jlua.iterator of Path
function Path:dir()
	local relative_children = vim.fn.readdir(tostring(self))
	return iter(relative_children):map(function(path)
		return self / path
	end)
end

--- Return files matching pattern in the directory pointed by this path.
--
-- @param pattern Pattern to match
--
-- @return A jlua.iterator of absolute paths matching the given pattern.
function Path:glob(pattern)
	local files = vim.fn.globpath(tostring(self), pattern, 0, true)
	return iter(files)
end

--- Check if a path points to a directory
--
-- @return True if the path points to a directory, false otherwise
function Path:is_dir()
	return vim.fn.isdirectory(tostring(self)) ~= 0
end

--- Check if a path points to a file
--
-- @return True if the path points to a file, false otherwise
function Path:is_file()
	return vim.fn.filereadable(tostring(self)) ~= 0
end

--- Convert a relative path to an absolute.
--
-- Will consider vim.fn.getcwd as the base path to make the path absolute. If
-- the path already is absolute, return a copy of it.
--
-- @return An absolute jlua.path
function Path:to_absolute()
	if self._is_absolute then
		return Path:wrap({
			_is_absolute = self._is_absolute,
			_parts = List(self._parts),
		})
	end

	return Path(vim.fn.getcwd()) / self
end

return Path
