---@type vim.lsp.Config
return {
  cmd = { "uvx", "ty", "server" },
  filetypes = { "python" },
  root_markers = { "ty.toml", "pyproject.toml", ".git" },
}
