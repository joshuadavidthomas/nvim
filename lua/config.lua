local M = {}

function M.setup()
  require("globals")
  require("options").setup()
  require("filetype")
  require("lang").setup()
  require("keymaps")
  require("autocmds")
  require("commands")
  require("lsp").setup()
end

return M
