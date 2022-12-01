local Path = require("gilbert.nvim.path")

local Suite = {}

function Suite.cwd()
	local current_dir = Path.cwd()
	assert_equals(tostring(current_dir), vim.fn.getcwd())
end

function Suite.dir()
	local data_dir = Path.cwd() / "tests/data/otters"
	assert_equals(data_dir:dir():to_list(), {
		data_dir / "peter.txt",
		data_dir / "steven.txt",
	})
end

function Suite.glob()
	local data_dir = Path.cwd() / "tests/data"
	assert_equals(data_dir:glob("**/*.txt"):to_list(), {
		tostring(data_dir / "otters/peter.txt"),
		tostring(data_dir / "otters/steven.txt"),
	})
end

function Suite.to_absolute()
	local steven = Path("tests/data/otters/peter.txt")
	assert_equals(steven:to_absolute(), Path(vim.fn.getcwd()) / steven)

	local absolute_steven = Path(vim.fn.getcwd()) / steven
	assert(absolute_steven.is_absolute)
	assert_equals(absolute_steven:to_absolute(), Path(vim.fn.getcwd()) / steven)
end

return Suite
