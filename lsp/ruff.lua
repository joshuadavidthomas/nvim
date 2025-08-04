---@type vim.lsp.Config
return {
  cmd = { "uvx", "ruff", "server" },
  cmd_env = { RUFF_TRACE = "messages" },
  filetypes = { "python" },
  init_options = {
    settings = {
      logLevel = "error",
    },
  },
  on_attach = function(client, _)
    -- Disable hover provider for ruff, in favor of pyright
    client.server_capabilities.hoverProvider = false
  end,
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml" },
  single_file_support = true,
}
