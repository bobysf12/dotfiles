return {
	"tpope/vim-fugitive",
	cmd = "Git",
	config = function()
		vim.api.nvim_set_keymap("n", "<leader>gs", ":Gstatus<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>gc", ":Gcommit<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>gp", ":Gpush<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>gl", ":Gpull<CR>", { noremap = true, silent = true })
	end,
}
