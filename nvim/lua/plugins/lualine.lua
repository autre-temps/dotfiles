-- lualine: a single statusline pinned to the bottom of the screen
-- (globalstatus = true, paired with laststatus = 3 in base.lua). Powerline-style
-- separators and Nerd Font icons (via nvim-web-devicons). The theme follows the
-- active colorscheme ("auto"), so the statusline restyles itself if the colors
-- ever change. noice (already installed) feeds the recording/search indicator.
return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        options = {
            theme = "auto",
            globalstatus = true,
            section_separators = { left = "", right = "" },
            component_separators = { left = "", right = "" },
        },
        sections = {
            lualine_a = { "mode" },
            -- diff stays empty until a diff source (e.g. gitsigns) is present;
            -- branch is detected by lualine on its own, no plugin needed.
            lualine_b = { "branch", "diff" },
            lualine_c = {
                {
                    "filename",
                    path = 1, -- relative path
                    symbols = { modified = " ●", readonly = " ", newfile = " " },
                },
                -- noice status: recording macro / search count, only when active.
                {
                    function()
                        return require("noice").api.statusline.mode.get()
                    end,
                    cond = function()
                        return package.loaded["noice"] ~= nil
                            and require("noice").api.statusline.mode.has()
                    end,
                },
            },
            lualine_x = {
                -- Names of the LSP clients attached to the current buffer.
                {
                    function()
                        local names = {}
                        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                            names[#names + 1] = client.name
                        end
                        return table.concat(names, ", ")
                    end,
                    icon = " ",
                    cond = function()
                        return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
                    end,
                },
                "diagnostics",
                "encoding",
                "filetype",
            },
            lualine_y = { "progress", "location" },
            lualine_z = {
                { "datetime", style = "%H:%M" },
            },
        },
    },
}
