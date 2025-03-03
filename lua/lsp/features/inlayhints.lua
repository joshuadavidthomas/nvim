local M = {}

---@class InlayHintsOptions
---@field enabled boolean
---@field exclude string[] Filetypes to exclude from inlay hints

---@param opts InlayHintsOptions
function M.setup(opts)
  if not opts.enabled or vim.fn.has("nvim-0.10") == 0 then
    return
  end

  local capabilities = require("lsp.capabilities")

  capabilities.on_supports_method("textDocument/inlayHint", function(_, buffer)
    if not capabilities.is_valid_buffer(buffer, opts.exclude) then
      return
    end

    vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
  end)
end

return M
