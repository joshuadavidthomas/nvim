local M = {}

---@class CodeLensOptions
---@field enabled boolean

---@param opts CodeLensOptions
function M.setup(opts)
  if not opts.enabled or not vim.lsp.codelens or vim.fn.has("nvim-0.10") == 0 then
    return
  end

  local capabilities = require("lsp.capabilities")

  capabilities.on_supports_method("textDocument/codeLens", function(_, buffer)
    if not capabilities.is_valid_buffer(buffer) then
      return
    end

    vim.lsp.codelens.refresh()
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      buffer = buffer,
      callback = vim.lsp.codelens.refresh,
    })
  end)
end

return M
