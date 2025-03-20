local p = require("utils.path")
local v = require("utils.vim")

local M = {}

M.lsp_dir = v.config_path("lsp")

---@param server_name string Server name to get config for
---@return string config_path Path to server configuration file
function M.config_path(server_name)
  local config_name = server_name .. ".lua"
  return p.join(M.lsp_dir, config_name)
end

---@param server_name string Server name to get config for
---@return table|nil Server configuration or nil if not found
function M.get_config(server_name)
  local config_path = M.config_path(server_name)

  if vim.fn.filereadable(config_path) == 1 then
    local ok, config = pcall(dofile, config_path)
    if ok and type(config) == "table" then
      return config
    end
  end

  return nil
end

---@return table List of server names from configuration files
function M.get_servers()
  local servers = {}

  local lsp_files = vim.fn.glob(M.lsp_dir .. "/*.lua", false, true)
  for _, file in ipairs(lsp_files) do
    local server = vim.fn.fnamemodify(file, ":t:r")
    table.insert(servers, server)
  end

  return servers
end

---@param servers table List of servers to ensure are installed
function M.ensure_installed(servers)
  local has_mason, mr = pcall(require, "mason-registry")

  if not has_mason then
    return
  end

  mr.refresh(function()
    for _, server in ipairs(servers) do
      local pkg_name = server
      local has_mappings, mapping = pcall(require, "mason-lspconfig.mappings.server")

      if has_mappings then
        pkg_name = mapping.lspconfig_to_package[server] or server
      end

      ---@diagnostic disable-next-line: redefined-local
      local p = mr.get_package(pkg_name)
      if p and not p:is_installed() then
        p:install()
      end
    end
  end)
end

-- Get the LSP client for a buffer
---@param server_name string Server name to get
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@return vim.lsp.Client|nil Client for server or nil if not found
function M.get_client(server_name, bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr or 0, name = server_name })[1]
end

---@param server_name string Server name to get
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@return boolean Whether the client is enabled
function M.is_enabled(server_name, bufnr)
  return M.get_client(server_name, bufnr or 0) ~= nil
end

-- Turn off an LSP client by name for a buffer
---@param server_name string The name of the LSP client to stop
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@return boolean Whether the client was running and is now stopped
function M.disable(server_name, bufnr)
  local client = M.get_client(server_name, bufnr or 0)
  if client then
    client:stop(true)
  end

  return client ~= nil
end

-- Turn on an LSP client by name for a buffer
---@param server_name string The name of the LSP client to start
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@return boolean Whether the client is now running
function M.enable(server_name, bufnr)
  bufnr = bufnr or 0

  if M.is_enabled(server_name, bufnr) then
    return true
  end

  local config = M.get_config(server_name)
  if not config then
    vim.notify("No configuration found for LSP: " .. server_name, vim.log.levels.ERROR)
    return false
  end

  config.bufnr = bufnr

  return vim.lsp.start(config) ~= nil
end

return M
