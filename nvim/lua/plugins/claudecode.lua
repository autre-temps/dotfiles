return {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
        "ClaudeCode",
        "ClaudeCodeFocus",
        "ClaudeCodeAdd",
        "ClaudeCodeSend",
        "ClaudeCodeTreeAdd",
        "ClaudeCodeDiffAccept",
        "ClaudeCodeDiffDeny",
    },
    keys = {
        { "<leader>a",  nil,                             desc = "Claude Code" },
        { "<leader>ac", "<cmd>ClaudeCode<cr>",           desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",      desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",  desc = "Resume Claude" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",      desc = "Add buffer" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>",       mode = "v",            desc = "Send selection" },
        {
            "<leader>as",
            "<cmd>ClaudeCodeTreeAdd<cr>",
            desc = "Add file",
            ft = { "oil", "netrw", "snacks_picker_list" },
        },
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    },
    opts = {
        terminal = {
            split_side = "right",
            split_width_percentage = 0.38,
        },
    },
}
