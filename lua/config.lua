local M = {}

function M.setup()
  require("globals")
  require("options").setup()
  require("keymaps")
  require("autocmds")
  require("commands")
end

return M
