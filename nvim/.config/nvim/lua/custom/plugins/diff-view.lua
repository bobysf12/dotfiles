return {
	"sindrets/diffview.nvim",
	config = function()
		local actions = require("diffview.actions")

		require("diffview").setup({
			keymaps = {
				view = {
					{ "n", "<leader>dco", actions.conflict_choose("ours"), { desc = "Choose the OURS version of a conflict" } },
					{ "n", "<leader>dct", actions.conflict_choose("theirs"), { desc = "Choose the THEIRS version of a conflict" } },
					{ "n", "<leader>dcb", actions.conflict_choose("base"), { desc = "Choose the BASE version of a conflict" } },
					{ "n", "<leader>dca", actions.conflict_choose("all"), { desc = "Choose all the versions of a conflict" } },
					{ "n", "<leader>dcO", actions.conflict_choose_all("ours"), { desc = "Choose OURS for whole file" } },
					{ "n", "<leader>dcT", actions.conflict_choose_all("theirs"), { desc = "Choose THEIRS for whole file" } },
					{ "n", "<leader>dcB", actions.conflict_choose_all("base"), { desc = "Choose BASE for whole file" } },
					{ "n", "<leader>dcA", actions.conflict_choose_all("all"), { desc = "Choose all for whole file" } },
				},
			},
		})

		vim.keymap.set("n", "<leader>dv", vim.cmd.DiffviewOpen, { desc = "[D]iff [V]iew Open" })
		vim.keymap.set("n", "<leader>dx", vim.cmd.DiffviewClose, { desc = "[D]iff [V]iew Close" })
		vim.keymap.set("n", "<leader>dh", vim.cmd.DiffviewFileHistory, { desc = "[D]iff File [H]istory" })
	end,
}
