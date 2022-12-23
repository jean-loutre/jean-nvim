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

function Suite.insert()
	local buffer = Buffer()
	local namespace = Namespace()
	local buffer_content = Range(buffer, namespace, 0, 0, 0, -1)

	local jean = buffer_content:insert({ "jean", "" })
	assert_equals(jean.text, { "jean", "" })
	assert_equals(buffer_content.text, { "jean", "" })

	local jacques = buffer_content:insert({ "jacques", "" })
	assert_equals(jacques.text, { "jacques", "" })
	assert_equals(buffer_content.text, { "jean", "jacques", "" })

	jean = jean:insert({ "-jean" }, 0, 4)
	local michel = jean:insert({ "-michel" }, 0, 5)
	assert_equals(buffer_content.text, { "jean-jean-michel", "jacques", "" })

	michel:insert({ "-pascal" }, 0, -8)
	assert_equals(
		buffer_content.text,
		{ "jean-jean-pascal-michel", "jacques", "" }
	)

	local pierre = buffer_content:insert({ "pierre-" }, -2, -7)
	assert_equals(
		buffer_content.text,
		{ "jean-jean-pascal-michel", "pierre-jacques", "" }
	)

	local rene = pierre:insert({ "-rené" }, -1, 6)
	assert_equals(
		buffer_content.text,
		{ "jean-jean-pascal-michel", "pierre-rené-jacques", "" }
	)

	rene:insert({ "jennyfer-" }, -1, -6)
	assert_equals(
		buffer_content.text,
		{ "jean-jean-pascal-michel", "pierre-jennyfer-rené-jacques", "" }
	)
end

function Suite.set_extmark()
	local buffer = Buffer()
	local namespace = Namespace()
	local buffer_content = Range(buffer, namespace, 0, 0, 0, -1)
	buffer_content.text = { "jean-jacques", "jean-pascal" }

	local mark = buffer_content:set_extmark(
		namespace,
		1,
		1,
		{ end_row = 1, end_col = -3, hl_group = "ErrorMsg" }
	)

	assert_equals(mark.position, { row = 1, col = 1 })
	assert_equals(mark.end_row, 1)
	assert_equals(mark.end_col, 9)
	assert_equals(mark.hl_group, "ErrorMsg")
end
return Suite
