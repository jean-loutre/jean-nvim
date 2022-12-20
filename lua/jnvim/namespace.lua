--- Object oriented wrapper around Neovim namespace.
---
--- Namespaces are used to scope buffer highlighting and marks.
---
--- @classmod jnvim.namespace.Namespace
local Object = require("jlua.object")

--- @class jnvim.Namespace
local Namespace = Object:extend()

---
--- Create a new namespace, or wraps an existing namespace.
---
--- Wraps vim.api.nvim_create_namespace. If no name argument is given, create
--- an anonymous namespace. If a namespace with the given name already exists
--- this instance will wrap this same namespace.
---
--- @tparam[opt=nil] string name Namespace name, or nil for an anonymous
--                               namespace.
function Namespace:init(name)
	self._ns_id = vim.api.nvim_create_namespace(name or "")
end

--- @function Namespace.properties.id:get()
--- Get the numerical id of this namespace.
--- @return number
function Namespace.properties.id:get()
	return self._ns_id
end

return Namespace
