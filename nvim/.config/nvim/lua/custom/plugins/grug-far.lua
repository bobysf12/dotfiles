return {
	"MagicDuck/grug-far.nvim",
	config = function()
		-- optional setup call to override plugin options
		-- alternatively you can set options with vim.g.grug_far = { ... }
		local grugFar = require("grug-far")

		grugFar.setup({
			-- options, see Configuration section below
			-- there are no required options atm
			-- engine = 'ripgrep' is default, but 'astgrep' or 'astgrep-rules' can
			-- be specified
		})

		vim.keymap.set({ "n", "i" }, "<leader>gf", function()
			grugFar.open()
		end, { desc = "[G]rug [F]ar - Search & Replace" })
	end,
}
