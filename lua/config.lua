local M = {}

function M.setup()
  require("globals")
  require("options").setup()
  require("filetype")
  require("projects").setup()
  require("keymaps")
  require("autocmds")
  require("commands")
  require("lsp").setup()
  vim.treesitter.language.register("twig", "nunjucks")
end

return M
