--- Luaunit test suite that reset the vim state before each test.
--
local TestSuite = {}

function TestSuite.setup()
	for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
		if buffer ~= 0 then
			vim.api.nvim_buf_delete(buffer, { force = true })
		end
	end
end

TestSuite.__index = TestSuite

return setmetatable(TestSuite, {
	__call = function()
		return setmetatable({}, TestSuite)
	end,
})
