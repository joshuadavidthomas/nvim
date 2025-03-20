local M = {}

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
function M.setup(opts)
  local capabilities = require("lsp.capabilities")
  local codelens = require("lsp.features.codelens")
  local diagnostics = require("lsp.diagnostics")
  local handlers = require("lsp.handlers")
  local icons = require("utils.icons")
  local inlayhints = require("lsp.features.inlayhints")

  opts = opts or {}

  -- Default workspace capabilities
  local workspace_capabilities = {
    workspace = {
      fileOperations = {
        didRename = true,
        willRename = true,
      },
    },
  }

  -- Get enhanced capabilities with workspace and user capabilities
  local enhanced_capabilities = capabilities.get_capabilities(opts.capabilities, workspace_capabilities)

  vim.lsp.config["*"] = {
    capabilities = enhanced_capabilities,
    diagnostics = opts.diagnostics or {
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
        },
      },
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "icons",
      },
    },
    inlay_hints = opts.inlay_hints or {
      enabled = true,
      exclude = {}, -- filetypes for which you don't want to enable inlay hints
    },
    codelens = opts.codelens or {
      enabled = false,
    },
  }

  -- Set up handler overrides for dynamic capabilities
  handlers.setup()

  -- Register method checking for both initial attach and dynamic capabilities
  M.on_attach(capabilities._check_methods)
  capabilities.on_dynamic_capability(capabilities._check_methods)

  -- Set up keymaps
  M.on_attach(function(client, buffer)
    require("lsp.keymaps").on_attach(client, buffer)
  end)
  capabilities.on_dynamic_capability(require("lsp.keymaps").on_attach)

  if opts.diagnostics ~= false then
    diagnostics.setup(vim.lsp.config["*"].diagnostics)
  end

  if opts.inlay_hints ~= false then
    inlayhints.setup(vim.lsp.config["*"].inlay_hints)
  end

  if opts.codelens ~= false then
    codelens.setup(vim.lsp.config["*"].codelens)
  end

  if opts.format_on_save and opts.format_on_save.enabled then
    require("lsp.features.format").setup_on_save(opts.format_on_save)
  end

  local servers = require("lsp.servers")
  local server_list = servers.get_servers()

  vim.lsp.enable(server_list)

  local augroup = vim.api.nvim_create_augroup("LspLazyInit", { clear = true })
  vim.api.nvim_create_autocmd(require("utils.lazy").lazyfile_event, {
    group = augroup,
    callback = function()
      vim.api.nvim_del_augroup_by_id(augroup)
      servers.ensure_installed(server_list)
    end,
    once = true,
  })
end

return M
