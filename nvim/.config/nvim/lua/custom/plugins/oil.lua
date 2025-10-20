return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
	config = function()
		require("oil").setup({
			win_options = {
				signcolumn = "yes:2",
			},
		})
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
}
