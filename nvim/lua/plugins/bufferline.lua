-- bufferline.nvim: open buffers shown as tabs along the top (tabline).
-- buffers mode (independent of Vim's tab pages, which the gh/gl/te keymaps drive),
-- with LSP diagnostics counts. Colors follow the active colorscheme (Dracula).
return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Bufferline: previous buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Bufferline: next buffer" },
		{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Bufferline: move buffer left" },
		{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Bufferline: move buffer right" },
		{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Bufferline: toggle pin" },
		{ "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Bufferline: close other buffers" },
	},
	opts = {
		options = {
			mode = "buffers",
			diagnostics = "nvim_lsp",
			-- slant separators echo lualine's powerline-style angled separators.
			separator_style = "slant",
			show_buffer_close_icons = true,
			show_close_icon = false,
			always_show_bufferline = true,
		},
	},
}
