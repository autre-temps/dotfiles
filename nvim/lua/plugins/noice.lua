-- Noice: render the cmdline (Ex mode) and search as a popup near the center of
-- the screen instead of the classic bottom line. nui.nvim is required; we pair
-- the cmdline and completion menu together via the command_palette preset.
-- nvim-notify gives messages/notifications a tidier floating UI.
return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    opts = {
        presets = {
            -- Keep cmdline and popupmenu grouped together, centered.
            command_palette = true,
        },
    },
}
