local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

local keymap = vim.api.nvim_set_keymap

keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

keymap("i", "<C-j>", "<ESC>", opts)
keymap("", "<C-j>", "<ESC>", opts)

keymap("n", "sh", "<C-w>h", opts)
keymap("n", "sj", "<C-w>j", opts)
keymap("n", "sk", "<C-w>k", opts)
keymap("n", "sl", "<C-w>l", opts)

keymap("n", "te", ":tabedit", opts)
keymap("n", "gn", ":tabedit<Return>", opts)
keymap("n", "gh", "gT", opts)
keymap("n", "gl", "gt", opts)

keymap("n", "ss", ":split<Return><C-w>w", opts)
keymap("n", "sv", ":vsplit<Return><C-w>w", opts)

keymap("n", "dw", 'vb"_d', opts)

keymap("n", "<Space>w", ":<C-u>w<Return>", opts)
keymap("n", "<Space>q", ":<C-u>q<Return>", opts)
keymap("n", "<Space>W", ":<C-u>w!<Return>", opts)
keymap("n", "<Space>Q", ":<C-u>q!<Return>", opts)
