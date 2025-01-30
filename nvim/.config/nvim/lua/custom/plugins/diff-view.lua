return {
	"sindrets/diffview.nvim",
	config = function()
		vim.keymap.set("n", "<leader>gd", vim.cmd.DiffviewOpen, { desc = "[G]it [D]iff View" })
	end,
}
