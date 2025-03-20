local v = require("utils.vim")

local M = {}

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
M._supports_method = {}

---@param method string
---@param fn fun(client:vim.lsp.Client, buffer)
function M.on_supports_method(method, fn)
  M._supports_method[method] = M._supports_method[method] or setmetatable({}, { __mode = "k" })
  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspSupportsMethod",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client and method == args.data.method then
        return fn(client, buffer)
      end
    end,
  })
end

---@param client vim.lsp.Client
---@param buffer number
function M._check_methods(client, buffer)
  if not v.is_valid_buffer(buffer) then
    return
  end

  for method, clients in pairs(M._supports_method) do
    clients[client] = clients[client] or {}
    if not clients[client][buffer] then
      if client.supports_method and client.supports_method(method, { bufnr = buffer }) then
        clients[client][buffer] = true
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspSupportsMethod",
          data = { client_id = client.id, buffer = buffer, method = method },
        })
      end
    end
  end
end

---@param fn fun(client:vim.lsp.Client, buffer):boolean?
---@param opts? {group?: integer}
function M.on_dynamic_capability(fn, opts)
  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspDynamicCapability",
    group = opts and opts.group or nil,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client then
        return fn(client, buffer)
      end
    end,
  })
end

---@param user_capabilities? table User-provided capabilities
---@param workspace_capabilities? table Default workspace file operations if not included in user_capabilities
---@return table
function M.get_capabilities(user_capabilities, workspace_capabilities)
  -- Start with base protocol capabilities
  local default_capabilities = vim.lsp.protocol.make_client_capabilities()

  -- Add workspace file operations if provided
  if workspace_capabilities then
    default_capabilities = vim.tbl_deep_extend("force", default_capabilities, workspace_capabilities)
  end

  -- Apply user-provided capabilities last so they take precedence
  if user_capabilities then
    default_capabilities = vim.tbl_deep_extend("force", default_capabilities, user_capabilities)
  end

  return default_capabilities
end

---Trigger dynamic capability update for a specific client or all clients
---@param client_id? integer Optional client ID. If nil, updates all clients
function M.trigger_dynamic_capabilities(client_id)
  if client_id then
    -- Update specific client
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
      for bufnr, _ in pairs(client.attached_buffers or {}) do
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspDynamicCapability",
          data = { client_id = client_id, buffer = bufnr },
        })
      end
    end
  else
    -- Update all clients
    for _, client in ipairs(vim.lsp.get_clients()) do
      for bufnr, _ in pairs(client.attached_buffers or {}) do
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspDynamicCapability",
          data = { client_id = client.id, buffer = bufnr },
        })
      end
    end
  end
end

return M
