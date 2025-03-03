local M = {}

local lsp = require("lsp")

---@class FormatOnSaveOptions
---@field enabled boolean
---@field timeout_ms number milliseconds before formatting times out

---@param opts FormatOnSaveOptions
function M.setup_on_save(opts)
  opts = opts or { enabled = false, timeout_ms = 3000 }

  lsp.on_attach(function(client, buffer)
    if not client.supports_method("textDocument/formatting") then
      return
    end

    -- Create the augroup if it doesn't exist, but don't clear existing commands
    -- We only want to clear autocommands for the specific buffer we're setting up
    local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = false })
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = buffer })

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = buffer,
      callback = function()
        require("utils.format").format({
          bufnr = buffer,
          timeout_ms = opts.timeout_ms,
        })
      end,
    })
  end)
end

return M
