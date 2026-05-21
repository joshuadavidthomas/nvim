---@type vim.lsp.Config
return {
  cmd = { "mdx-language-server", "--stdio" },
  filetypes = { "mdx" },
  root_markers = { "package.json", ".git" },
  init_options = {
    typescript = {
      enabled = true,
    },
  },
  settings = {
    mdx = {
      validate = {
        validateReferences = "warning",
        validateFragmentLinks = "warning",
        validateFileLinks = "warning",
      },
    },
  },
}
