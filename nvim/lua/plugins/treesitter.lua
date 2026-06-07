-- Syntax/indent via Tree-sitter. Debian's Neovim bundles no python parser, so
-- nvim-treesitter installs it (and builds with the system C compiler).
return {
    "nvim-treesitter/nvim-treesitter",
    -- master = the classic module API (require("nvim-treesitter.configs"));
    -- the new default `main` branch has a different, still-transitioning API.
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = { "python" },
            highlight = {
                enable = true,
                -- lua is already highlighted by Debian's runtime ftplugin.
                disable = { "lua" },
            },
            indent = { enable = true },
        })
    end,
}
