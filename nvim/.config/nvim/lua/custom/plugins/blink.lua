return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets", -- Common TypeScript/JS snippets
	},

	-- use a release tag to download pre-built binaries
	version = "v1.*",
	-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'cargo build --release',
	-- If you use nix, you can build from source using latest nightly rust with:
	-- build = 'nix run .#build-plugin',

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		-- 'default' for mappings similar to built-in completion
		-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
		-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
		-- see the "default configuration" section below for full documentation on how to define
		-- your own keymap.
		keymap = { preset = "default" },

		appearance = {
			-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
			-- Adjusts spacing to ensure icons are aligned
			nerd_font_variant = "mono",
		},

		completion = {
			-- ENHANCEMENT: Auto-show docs with debounce
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500, -- Show after 500ms of hovering
			},

			-- PERFORMANCE: Smart triggers for better UX
			trigger = {
				show_on_insert_on_trigger_character = true,
			},

			-- PERFORMANCE: Limit items for huge completion lists
			list = {
				max_items = 200, -- Prevents slowdown on massive lists
			},

			menu = {
				-- ENHANCEMENT: Better visual selection
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
				},
			},
		},

		-- default list of enabled providers defined so that you can extend it
		-- elsewhere in your config, without redefining it, via `opts_extend`
		sources = {
			default = { "lazydev", "lsp", "path", "snippets", "buffer" },
			-- optionally disable cmdline completions
			-- cmdline = {},
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					-- make lazydev completions top priority (see `:h blink.cmp`)
					score_offset = 100,
				},

				-- PERFORMANCE: Configure LSP source
				lsp = {
					name = "LSP",
					-- OPTIMIZATION: Async fetching with timeout
					timeout_ms = 1000,
				},

				-- PERFORMANCE: Buffer source optimization
				buffer = {
					name = "Buffer",
					max_items = 5, -- Limit buffer completions
					min_keyword_length = 3, -- Don't complete on 1-2 chars
				},
			},
		},

		-- ENHANCEMENT: Enable signature help (fast in blink!)
		signature = {
			enabled = true,
			window = {
				border = "rounded",
			},
		},
	},
	-- allows extending the providers array elsewhere in your config
	-- without having to redefine it
	opts_extend = { "sources.default" },
}
