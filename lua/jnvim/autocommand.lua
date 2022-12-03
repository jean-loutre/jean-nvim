--- Wrapper around autocommand wrapping callbacks arguments in jlua / jnvim
-- wrappers
local Object = require("jlua.object")

local Buffer = require("jnvim.buffer")
local Path = require("jnvim.path")
local map_table = require("jnvim.api").map_table

--- Object-oriented wrapper around nvim autocommands
local Autocommand = Object:extend()

--- Object-oriented wrapper around nvim autocommand groups.
Autocommand.Group = Object:extend()

--- Initialize the group
--
-- @param name: name of the autocommand group.
-- @param clear: clear the group on creation.
function Autocommand.Group:init(name, clear)
	self._handle = vim.api.nvim_create_augroup(name, { clear = clear })
end

--- Get the underlying group id
function Autocommand.Group.properties.handle:get()
	assert(self._handle)
	return self._handle
end

--- Create a group from a group id.
--
-- Parameters
-- ----------
-- handle : int
--     The nvim id of the group to wrap.
--
-- Return
-- ------
-- A new instance of AutocommandGroup
function Autocommand.Group.from_handle(handle)
	return Autocommand.Group:wrap({
		_handle = handle,
	})
end

--- Add an autocmmand to this group
--
-- @param event: The event to pass to the init function of Autocommand
-- @param options: Options to pass to the autocommand
--
-- @return An instance of jnvim.autocommand
function Autocommand.Group:add(event, options)
	assert(self._handle ~= nil)
	options.group = self
	return Autocommand(event, options)
end

--- Delete the group
--
-- The Group instance will not be usable after this call, so don't use it.
function Autocommand.Group:delete()
	assert(self._handle ~= nil)
	vim.api.nvim_del_augroup_by_id(self._handle)
	self._handle = nil
end

--- Create a new autocommand
function Autocommand:init(event, options)
	if options.callback then
		local wrapped_callback = options.callback
		options.callback = function(args)
			assert(args.id == self._handle)
			return wrapped_callback(map_table(args, {
				{ "group", Autocommand.Group.from_handle },
				{ "buf", Buffer.from_handle },
				{ "file", Path },
			}))
		end
	end

	self._handle = vim.api.nvim_create_autocmd(event, options)
end

function Autocommand:delete()
	assert(self._handle ~= nil)
	vim.api.nvim_del_autocmd(self._handle)
	self._handle = nil
end

return Autocommand
