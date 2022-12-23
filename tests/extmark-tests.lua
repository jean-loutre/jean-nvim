local Buffer = require("jnvim.buffer")
local Extmark = require("jnvim.extmark")
local Namespace = require("jnvim.namespace")

local TestSuite = require("jnvim.test-suite")

local Suite = TestSuite()

function Suite.property_get_set()
	local buffer = Buffer()
	local namespace = Namespace()
	local mark = Extmark(buffer, namespace, 1, 0, {})
	mark.hl_group = "ErrorMsg"
	assert_equals(mark.hl_group, "ErrorMsg")
	assert_equals(mark.position, { row = 1, col = 0 })
end

return Suite
