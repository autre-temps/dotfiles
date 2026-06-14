return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local fzf = require("fzf-lua")

        fzf.setup({
            -- fzf binary path (installed via ~/.fzf)
            fzf_bin = vim.fn.expand("~/.fzf/bin/fzf"),
            winopts = {
                height = 0.85,
                width  = 0.80,
                preview = {
                    default  = "builtin",  -- no bat required
                    layout   = "vertical",
                    vertical = "down:45%",
                },
            },
            -- Fallback to grep when rg is unavailable
            grep = {
                grep_opts = "--binary-files=without-match --line-number --recursive --color=never -e",
            },
        })

        local map  = vim.keymap.set
        local desc = function(d) return { silent = true, desc = "FZF: " .. d } end

        -- Files & buffers
        map("n", "<Space>ff", fzf.files,    desc("find files"))
        map("n", "<Space>fr", fzf.oldfiles, desc("recent files"))
        map("n", "<Space>fb", fzf.buffers,  desc("buffers"))

        -- Grep
        map("n", "<Space>fg", fzf.live_grep,   desc("live grep"))
        map("v", "<Space>fg", fzf.grep_visual, desc("grep selection"))
        map("n", "<Space>fw", fzf.grep_cword,  desc("grep word under cursor"))
        map("n", "<Space>fc", fzf.blines,      desc("buffer lines"))

        -- LSP
        map("n", "<Space>ls", fzf.lsp_document_symbols,  desc("document symbols"))
        map("n", "<Space>lS", fzf.lsp_workspace_symbols, desc("workspace symbols"))
        map("n", "<Space>ld", fzf.diagnostics_document,  desc("diagnostics (buffer)"))
        map("n", "<Space>lD", fzf.diagnostics_workspace, desc("diagnostics (workspace)"))

        -- Git
        map("n", "<Space>gc", fzf.git_commits, desc("git commits"))
        map("n", "<Space>gs", fzf.git_status,  desc("git status"))

        -- Misc
        map("n", "<Space>fh", fzf.help_tags,      desc("help tags"))
        map("n", "<Space>fk", fzf.keymaps,        desc("keymaps"))
        map("n", "<Space>f:", fzf.command_history, desc("command history"))
    end,
}
