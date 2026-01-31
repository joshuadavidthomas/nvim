local file = require("utils.file")

local M = {}

-- Path constants
M.DISABLED_SERVERS_PATH = vim.fn.stdpath("data") .. "/lsp_disabled_servers"
M.ENABLED_SERVERS_PATH = vim.fn.stdpath("data") .. "/lsp_enabled_servers"

-- Load disabled servers from file
function M.load_disabled_servers()
  local content = file.read_file(M.DISABLED_SERVERS_PATH)
  if not content then
    return {}
  end

  local disabled = {}
  for line in content:gmatch("[^\n]+") do
    line = vim.trim(line)
    if line ~= "" and not line:match("^#") then
      table.insert(disabled, line)
    end
  end
  return disabled
end

-- Load enabled servers from file
function M.load_enabled_servers()
  local content = file.read_file(M.ENABLED_SERVERS_PATH)
  if not content then
    return {}
  end

  local enabled = {}
  for line in content:gmatch("[^\n]+") do
    line = vim.trim(line)
    if line ~= "" and not line:match("^#") then
      table.insert(enabled, line)
    end
  end
  return enabled
end

-- Save disabled servers to file
function M.save_disabled_servers(disabled_list)
  local success = file.write_file(M.DISABLED_SERVERS_PATH, disabled_list)
  if not success then
    vim.notify("Failed to save disabled LSP servers", vim.log.levels.ERROR)
  end
end

-- Save enabled servers to file
function M.save_enabled_servers(enabled_list)
  local success = file.write_file(M.ENABLED_SERVERS_PATH, enabled_list)
  if not success then
    vim.notify("Failed to save enabled LSP servers", vim.log.levels.ERROR)
  end
end

-- Check if server has global disable entry
function M.has_global_disable(server_name, disabled_list)
  disabled_list = disabled_list or M.load_disabled_servers()
  local global_entry = "*:" .. server_name
  return vim.tbl_contains(disabled_list, global_entry)
end

-- Check if server has project disable entry
function M.has_project_disable(server_name, project_root, disabled_list)
  disabled_list = disabled_list or M.load_disabled_servers()
  local project_entry = project_root .. ":" .. server_name
  return vim.tbl_contains(disabled_list, project_entry)
end

-- Remove only project entries for a specific server from a list
function M.remove_project_entries_for_server(server_name, list)
  local new_list = {}
  local removed_any = false
  for _, entry in ipairs(list) do
    local entry_server = entry:match(":([^:]+)$")
    if entry_server ~= server_name or entry:match("^%*:") then
      table.insert(new_list, entry)
    else
      removed_any = true
    end
  end
  return new_list, removed_any
end

-- Apply persistent server state (typically called on startup)
function M.setup()
  local servers = require("lsp.servers")
  local project = require("utils.project")
  local all_servers = servers.get_servers()
  local project_root = project.get_buffer_root()

  for _, server_name in ipairs(all_servers) do
    local should_enable = servers.should_be_enabled(server_name, project_root)
    vim.lsp.enable(server_name, should_enable)
  end
end

return M
