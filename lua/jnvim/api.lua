--- Utilities for mapping nvim api to custom wrapper types.
local Map = require("jlua.map")

local api = {}

--- Return a jlua.Map from a table received nvim, mapping certain keys.
--
-- For each element in the mappings table, will apply the function if
-- the key is present.
--
-- Parameters
-- ----------
-- table : {*}
--      Lua table received from the nvim api to map.
-- mappings : { {string, function(*)->*} }
--      List of key / mapping function to apply to the table elements.
--
-- Returns
-- ------
-- {*}
--     Mapped table, as a `jlua.Map`
--
function api.map_table(table, mappings)
	for _, mapping in ipairs(mappings) do
		local key, mapper = unpack(mapping)
		if table[key] then
			table[key] = mapper(table[key])
		end
	end
	return Map:wrap(table)
end

return api
