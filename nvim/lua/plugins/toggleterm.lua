-- Toggleterm: toggle a terminal with <C-\> (works from both normal and
-- terminal mode). Opens as a floating window. Pinned to release tags.
return {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    opts = {
        open_mapping = [[<c-\>]],
        direction = "float",
    },
}
