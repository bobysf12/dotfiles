return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	lazy = true,
	keys = {
		{
			"<leader>ls",
			function()
				vim.cmd("LspStart")
			end,
			desc = "[L]SP [S]tart",
		},
	},
	opts = {
		autostart = false,
		on_attach = function(client, bufnr)
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end,
		settings = {
			-- PERFORMANCE: Separate diagnostic server for 30% resource reduction
			separate_diagnostic_server = true,

			-- PERFORMANCE: Only show diagnostics on save, not during typing
			publish_diagnostic_on = "insert_leave",

			-- PERFORMANCE: Limit memory to 4GB (adjust based on your projects)
			tsserver_max_memory = 4096,

			-- PERFORMANCE: Disable function call completions (blink handles this better)
			complete_function_calls = false,

			-- PERFORMANCE: Expose useful code actions without overhead
			expose_as_code_action = {
				"add_missing_imports",
				"organize_imports",
				"remove_unused_imports",
			},

			tsserver_file_preferences = {
				-- OPTIMIZED INLAY HINTS: Only show essential ones
				-- Keep parameter names (useful for understanding function calls)
				includeInlayParameterNameHints = "literals", -- Only for literals, not all
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,

				-- Disable type hints (reduces 50% of hint processing)
				includeInlayFunctionParameterTypeHints = false,
				includeInlayVariableTypeHints = false,
				includeInlayVariableTypeHintsWhenTypeMatchesName = false,
				includeInlayPropertyDeclarationTypeHints = false,
				includeInlayFunctionLikeReturnTypeHints = false,

				-- Keep enum hints (minimal overhead, high value)
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
}
