-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- `mapleader` / `maplocalleader` are set in lua/keymaps.lua, which init.lua
-- requires before this file — so they are already in place before lazy.nvim
-- loads and mappings resolve correctly. Keep them defined in one place only.

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- automatically check for plugin updates
  checker = { enabled = true },
  -- Debian ships treesitter parsers in /usr/lib/nvim/parser. lazy.nvim resets
  -- the runtimepath by default and would drop that dir, so the runtime's
  -- `vim.treesitter.start()` (ftplugin/lua.lua) fails with "no parser for 'lua'".
  -- Keep it on the runtimepath here.
  performance = {
    rtp = {
      paths = { "/usr/lib/nvim" },
    },
  },
})
