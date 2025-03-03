local M = {}

---@param opts? {bufnr?: number, timeout_ms?: number}
function M.format(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local timeout_ms = opts.timeout_ms or 3000

  local ok, conform = pcall(require, "conform")
  if ok then
    local result = conform.format({ bufnr = bufnr, timeout_ms = timeout_ms })

    if result then
      return
    end
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })

  if #clients > 0 then
    vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = timeout_ms })
  else
    vim.notify("No formatting providers available for this buffer", vim.log.levels.WARN)
  end
end

return M
