formatter = "plain"
exclude_files = { "third-party" }

stds.luaunit = {
	globals = { "LuaUnit" },
	read_globals = {
		"assert_equals",
		"assert_error_msg_contains",
		"assert_is_false",
		"assert_is_nil",
		"assert_is_true",
		"assert_not_equals",
		"assert_not_nil",
	},
}

stds.nvim = {
	read_globals = {
		vim = {
			fields = {
				bo = {
					read_only = false,
					other_fields = true,
				},
				api = {
					fields = {
						"nvim_buf_delete",
						"nvim_buf_get_name",
						"nvim_buf_set_name",
						"nvim_command",
						"nvim_create_autocmd",
						"nvim_create_buf",
						"nvim_del_autocmd",
						"nvim_exec_autocmds",
						"nvim_get_current_buf",
						"nvim_list_bufs",
					},
				},

				fn = {
					read_only = false,
					other_fields = true,
				},
			},
		},
	},
}

std = "max+luaunit+nvim"
