-- Tree-sitter parser manager. nvim-treesitter was archived; this plugin
-- provides parser installation and highlighting as a lightweight replacement.
-- Parser installation requires tree-sitter CLI (bun install -g tree-sitter-cli)
-- and a C compiler. Use :TSManager / :TSInstall / :TSUninstall to manage parsers.
return {
    "romus204/tree-sitter-manager.nvim",
    lazy = false,
    config = function()
        require("tree-sitter-manager").setup({
            auto_install = true,
            -- skip parsers bundled with Neovim
            noauto_install = { "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc" },
            -- Debian's runtime ftplugin already handles lua highlighting
            nohighlight = { "lua" },
        })
    end,
}
