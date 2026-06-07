-- Formatting on save via ruff (organize imports + format). Uses the ruff
-- binary that Mason installs; does not rely on LSP formatting.
return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
        formatters_by_ft = {
            python = { "ruff_organize_imports", "ruff_format" },
        },
        format_on_save = {
            timeout_ms = 1000,
            lsp_format = "never",
        },
    },
}
