-- Oil: edit the filesystem like a normal buffer. `-` opens the parent
-- directory; create/rename/delete files by editing the buffer and :w.
-- Loaded eagerly (lazy = false) so it can replace netrw and let `nvim .`
-- open a directory in oil.
return {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
        { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
}
