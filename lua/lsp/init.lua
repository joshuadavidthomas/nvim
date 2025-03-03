local capabilities = require("lsp.capabilities")
local handlers = require("lsp.handlers")
local diagnostics = require("lsp.diagnostics")
local inlayhints = require("lsp.features.inlayhints")
local codelens = require("lsp.features.codelens")

local M = {}

-- Export key functions from modules
M.on_supports_method = capabilities.on_supports_method
M.on_dynamic_capability = capabilities.on_dynamic_capability
M.get_capabilities = capabilities.get_capabilities

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
---@return number autocmd_id The autocmd ID that can be used to remove this autocmd
function M.on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf ---@type number
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        return on_attach(client, buffer)
      end
    end,
  })
end

---@param opts table|nil LSP configuration options
---@return table The module for chaining
function M.setup(opts)
  opts = opts or {}

  -- Set up handler overrides for dynamic capabilities
  handlers.setup()

  -- Register method checking for both initial attach and dynamic capabilities
  M.on_attach(capabilities._check_methods)
  M.on_dynamic_capability(capabilities._check_methods)

  -- Set up keymaps
  M.on_attach(function(client, buffer)
    require("lsp.keymaps").on_attach(client, buffer)
  end)
  M.on_dynamic_capability(require("lsp.keymaps").on_attach)

  -- Set up optional features
  if opts.diagnostics then
    diagnostics.setup(opts.diagnostics)
  end

  if opts.inlay_hints then
    inlayhints.setup(opts.inlay_hints)
  end

  if opts.codelens then
    codelens.setup(opts.codelens)
  end

  if opts.format_on_save and opts.format_on_save.enabled then
    require("lsp.features.format").setup_on_save(opts.format_on_save)
  end

  return M
end

return M
