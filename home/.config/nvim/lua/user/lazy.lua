
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup({ { import = "user.plugins" }, { import = "user.plugins.lsp" } }, {
  install = {
    colorscheme = { "rose-pine" },
  },
  checker = {
    enabled = false,  -- Check to see there are updates to plugins (i.e. the plugin repo)
    notify = true,
  },
  change_detection = {
    notify = true,
  },
})
