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
  if not M.is_valid_buffer(buffer) then
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

---@param capabilities? table
---@return table
function M.get_capabilities(capabilities)
  capabilities = capabilities or {}

  local default_capabilities = vim.lsp.protocol.make_client_capabilities()

  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink then
    default_capabilities = vim.tbl_deep_extend("force", default_capabilities, blink.get_lsp_capabilities())
  end

  return vim.tbl_deep_extend("force", default_capabilities, capabilities)
end

---@param buffer number The buffer number to check
---@param exclude_filetypes? string[] Optional list of filetypes to exclude
---@return boolean valid Whether the buffer is valid and should be processed
function M.is_valid_buffer(buffer, exclude_filetypes)
  -- Skip invalid buffers, non-listed buffers, and special buffers
  if not vim.api.nvim_buf_is_valid(buffer) or not vim.bo[buffer].buflisted or vim.bo[buffer].buftype == "nofile" then
    return false
  end

  if exclude_filetypes and vim.tbl_contains(exclude_filetypes, vim.bo[buffer].filetype) then
    return false
  end

  return true
end

return M
