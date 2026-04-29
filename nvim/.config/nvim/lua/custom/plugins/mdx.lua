return {
	"davidmh/mdx.nvim",
	config = function()
		local ok, mdx = pcall(require, "mdx")
		if ok and type(mdx.setup) == "function" then
			mdx.setup()
		end
	end,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
}
