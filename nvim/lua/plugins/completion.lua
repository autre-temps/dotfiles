-- Completion engine. Pinned to a release tag so the prebuilt fuzzy-matcher
-- binary is downloaded (no Rust toolchain required).
return {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
        -- <C-y> accept, <C-n>/<C-p> select, <C-space> toggle, <C-e> cancel
        keymap = { preset = "default" },
        appearance = { nerd_font_variant = "mono" },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        completion = {
            documentation = { auto_show = true, auto_show_delay_ms = 200 },
        },
        signature = { enabled = true },
    },
}
