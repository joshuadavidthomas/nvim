require("config.lazy")

vim.notify("Welcome to Neovim", "info", {
  title = "Neovim",
  timeout = 1000,
})

require("config.user_commands")
