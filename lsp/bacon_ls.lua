---@type vim.lsp.Config
return {
  cmd = { "bacon-ls" },
  filetypes = { "rust" },
  root_markers = {
    ".bacon-locations",
    ".git",
    "Cargo.lock",
    "Cargo.toml",
  },
  init_options = {
    updateOnSave = true,
    updateOnSaveWaitMillis = 1000,
  },
  single_file_support = true,
}
