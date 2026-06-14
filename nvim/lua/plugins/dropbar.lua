-- dropbar.nvim: IDE-like winbar breadcrumbs with LSP/Treesitter/Markdown sources.
-- <leader>; で現在位置のシンボル曖昧検索ピッカーを開く。
return {
	"Bekaboo/dropbar.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{
			"<leader>;",
			function()
				require("dropbar.api").pick()
			end,
			desc = "Dropbar: pick symbol",
		},
	},
	opts = {
		bar = {
			-- ソースは LSP → Treesitter でフォールバック。Markdown は専用ソースを使用。
			sources = function(buf, _)
				local sources = require("dropbar.sources")
				local utils = require("dropbar.utils")
				if vim.bo[buf].ft == "markdown" then
					return { sources.markdown }
				end
				return {
					utils.source.fallback({
						sources.lsp,
						sources.treesitter,
					}),
				}
			end,
		},
	},
}
