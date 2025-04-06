local M = {}

function M.lazy_init()
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

  require("utils.lazy").add_lazyfile_event()
end

M.setup = function()
  M.lazy_init()
  require("lazy").setup({
    checker = {
      enabled = true,
    },
    dev = {
      path = vim.fn.stdpath("config") .. "/lib",
      patterns = {
        "joshuadavidthomas",
      },
      fallback = false,
    },
    install = {
      colorscheme = { "tokyonight" },
    },
    performance = {
      rtp = {
        -- disable some rtp plugins
        disabled_plugins = {
          "gzip",
          "matchit",
          -- "matchparen",
          "netrwPlugin",
          -- "rplugin",
          "tarPlugin",
          "tohtml",
          "zipPlugin",
        },
      },
    },
    spec = {
      { import = "plugins" },
      { import = "plugins.lang" },
      "joshuadavidthomas/spotify.nvim",
    },
  })
  require("config").setup()
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

M.setup()

return M
