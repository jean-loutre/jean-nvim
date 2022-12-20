local Buffer = require("jnvim.buffer")
local Range = require("jnvim.range")
local Namespace = require("jnvim.namespace")

local TestSuite = require("jnvim.test-suite")

local Suite = TestSuite()

function Suite.property_text()
	local buffer = Buffer()
	local namespace = Namespace()
	local range = Range(buffer, namespace, 0, 0, 0, -1)

	range.text = { "kipity", "pobity", "otterity" }
	assert_equals(range.text, { "kipity", "pobity", "otterity" })

	local sub_range = Range(buffer, namespace, 0, 2, 1, 2)
	assert_equals(sub_range.text, { "pity", "po" })

	sub_range.text = { "llity", "sta" }
	assert_equals(sub_range.text, { "llity", "sta" })
	assert_equals(range.text, { "killity", "stabity", "otterity" })

	sub_range.text = { "" }
	assert_equals(sub_range.text, { "" })
	assert_equals(range.text, { "kibity", "otterity" })
end

return Suite
