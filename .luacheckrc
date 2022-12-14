formatter = "plain"
exclude_files = { "third-party" }

stds.luaunit = {
	globals = { "LuaUnit" },
	read_globals = {
		"assert_equals",
		"assert_error_msg_contains",
		"assert_false",
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
				"cmd",

				bo = {
					read_only = false,
					other_fields = true,
				},
				api = {
					fields = {
						"nvim_buf_delete",
						"nvim_buf_get_name",
						"nvim_buf_set_name",
						"nvim_clear_autocmds",
						"nvim_command",
						"nvim_create_augroup",
						"nvim_create_autocmd",
						"nvim_create_buf",
						"nvim_create_user_command",
						"nvim_del_augroup_by_id",
						"nvim_del_autocmd",
						"nvim_del_keymap",
						"nvim_del_user_command",
						"nvim_exec_autocmds",
						"nvim_get_current_buf",
						"nvim_list_bufs",
						"nvim_set_keymap",
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
