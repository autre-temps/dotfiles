-- render-markdown: pretty in-buffer rendering of Markdown (headings, bullets,
-- code blocks, tables, quotes) right where you edit the text. Toggle the
-- prettified view with :RenderMarkdown toggle. Lazily loaded for markdown
-- buffers; depends on the markdown / markdown_inline parsers (see tree-sitter-manager.lua).
return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = "markdown",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = {},
}
