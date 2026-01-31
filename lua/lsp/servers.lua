local p = require("utils.path")
local v = require("utils.vim")
local state = require("lsp.state")
local project = require("utils.project")

local M = {}

---@param server_name string Server name to get config for
---@return table|nil Server configuration or nil if not found
function M.get_config(server_name)
  local config_name = server_name .. ".lua"
  local config_path = p.join(v.config_path("lsp"), config_name)

  if vim.fn.filereadable(config_path) == 1 then
    local ok, config = pcall(dofile, config_path)
    if ok and type(config) == "table" then
      return config
    end
  end

  return nil
end

---@param filetype? string Optional filetype to filter servers by
---@return table List of server names from configuration files
function M.get_servers(filetype)
  local servers = {}

  local lsp_files = vim.fn.glob(v.config_path("lsp") .. "/*.lua", false, true)
  for _, file in ipairs(lsp_files) do
    local server_name = vim.fn.fnamemodify(file, ":t:r")

    if not filetype then
      table.insert(servers, server_name)
    else
      local config = M.get_config(server_name)
      if config and config.filetypes and vim.tbl_contains(config.filetypes, filetype) then
        table.insert(servers, server_name)
      end
    end
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
      local config = M.get_config(server)
      if config and config.cmd then
        local cmd = config.cmd[1]
        if vim.fn.executable(cmd) == 1 then
          -- already available on PATH
          goto continue
        end
      end

      local pkg_name = server
      local has_mappings, mappings = pcall(require, "mason-lspconfig.mappings")

      if has_mappings then
        local server_mapping = mappings.get_mason_map()
        pkg_name = server_mapping.lspconfig_to_package[server] or server
      end

      local has_pkg, pkg = pcall(mr.get_package, pkg_name)
      if has_pkg and pkg and not pkg:is_installed() then
        pkg:install()
      end

      ::continue::
    end
  end)
end

-- Check if server should be enabled based on persistent state
---@param server_name string Server name to check
---@param project_root? string Project root (defaults to current project)
---@return boolean Whether the server should be enabled
function M.should_be_enabled(server_name, project_root)
  project_root = project_root or project.get_buffer_root()
  local disabled_list = state.load_disabled_servers()
  local enabled_list = state.load_enabled_servers()

  -- Check for project-specific enable override (takes highest precedence)
  if vim.tbl_contains(enabled_list, project_root .. ":" .. server_name) then
    return true
  end

  -- Check for project-specific disable (takes precedence over global)
  if vim.tbl_contains(disabled_list, project_root .. ":" .. server_name) then
    return false
  end

  -- Check for global disable
  if vim.tbl_contains(disabled_list, "*:" .. server_name) then
    return false
  end

  -- Default: enabled
  return true
end

-- Disable server persistently (runtime + saved state)
---@param server_name string Server name to disable
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@param global? boolean Whether to disable globally (default: project-specific)
---@return boolean Whether the operation succeeded
function M.disable_persistent(server_name, bufnr, global)
  bufnr = bufnr or 0
  local project_root = project.get_buffer_root()

  -- Disable runtime
  vim.lsp.enable(server_name, false)

  local disabled_list = state.load_disabled_servers()
  local changes_made = false

  if global then
    -- Global disable: add global entry and remove any project disables
    local global_entry = "*:" .. server_name
    if not vim.tbl_contains(disabled_list, global_entry) then
      table.insert(disabled_list, global_entry)
      changes_made = true
    end

    -- Remove project disables (now redundant)
    local new_disabled_list, removed_any = state.remove_project_entries_for_server(server_name, disabled_list)
    if removed_any then
      disabled_list = new_disabled_list
      changes_made = true
    end
  else
    -- Project disable: only add if not already globally disabled
    if not state.has_global_disable(server_name, disabled_list) then
      local project_entry = project_root .. ":" .. server_name
      if not vim.tbl_contains(disabled_list, project_entry) then
        table.insert(disabled_list, project_entry)
        changes_made = true
      end
    end
  end

  if changes_made then
    state.save_disabled_servers(disabled_list)
  end

  local scope = global and "globally" or ("for project " .. vim.fn.fnamemodify(project_root, ":t"))
  vim.notify(string.format("Disabled LSP %s %s", server_name, scope), vim.log.levels.INFO)

  return true
end

-- Enable server persistently (runtime + update persistent state)
---@param server_name string Server name to enable
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@param global? boolean Whether this is a global enable (default: false for project-specific)
---@return boolean Whether the operation succeeded
function M.enable_persistent(server_name, bufnr, global)
  bufnr = bufnr or 0
  local project_root = project.get_buffer_root()

  local disabled_list = state.load_disabled_servers()
  local enabled_list = state.load_enabled_servers()
  local global_disabled_entry = "*:" .. server_name
  local project_disabled_entry = project_root .. ":" .. server_name
  local project_enabled_entry = project_root .. ":" .. server_name

  if global then
    -- Global enable: remove ONLY global disabled entry, keep project disables
    local new_disabled_list = {}
    local found_global_disable = false
    for _, entry in ipairs(disabled_list) do
      if entry ~= global_disabled_entry then
        table.insert(new_disabled_list, entry)
      else
        found_global_disable = true
      end
    end
    if found_global_disable then
      state.save_disabled_servers(new_disabled_list)
    end

    -- Remove any project-specific enabled overrides (no longer needed)
    local new_enabled_list = {}
    local found_project_enable = false
    for _, entry in ipairs(enabled_list) do
      local entry_server = entry:match(":([^:]+)$")
      if entry_server ~= server_name then
        table.insert(new_enabled_list, entry)
      else
        found_project_enable = true
      end
    end
    if found_project_enable then
      state.save_enabled_servers(new_enabled_list)
    end
  else
    if state.has_project_disable(server_name, project_root, disabled_list) then
      local new_disabled_list = {}
      for _, entry in ipairs(disabled_list) do
        if entry ~= project_disabled_entry then
          table.insert(new_disabled_list, entry)
        end
      end
      state.save_disabled_servers(new_disabled_list)
    elseif state.has_global_disable(server_name, disabled_list) then
      -- Server is globally disabled - add project-specific enable override
      -- DO NOT remove the global disable - leave it in place
      if not vim.tbl_contains(enabled_list, project_enabled_entry) then
        table.insert(enabled_list, project_enabled_entry)
        state.save_enabled_servers(enabled_list)
      end
    end
    -- If neither globally nor project disabled, no persistent changes needed
  end

  -- Enable the server
  vim.lsp.enable(server_name, true)

  local scope = global and "globally" or ("for project " .. vim.fn.fnamemodify(project_root, ":t"))
  vim.notify(string.format("Enabled LSP %s %s", server_name, scope), vim.log.levels.INFO)

  return true
end

-- Toggle a specific server on/off
---@param server_name string Server name to toggle
---@param bufnr? number Buffer number (default: 0 for current buffer)
---@param global? boolean Whether to toggle globally (default: project-specific)
---@return boolean Whether the operation succeeded
function M.toggle_server(server_name, bufnr, global)
  bufnr = bufnr or 0
  local filetype = vim.bo[bufnr].filetype

  -- Validate server is available for this filetype
  local available = M.get_servers(filetype)
  if not vim.tbl_contains(available, server_name) then
    vim.notify(string.format("Server '%s' not available for filetype '%s'", server_name, filetype), vim.log.levels.ERROR)
    return false
  end

  if global then
    -- Global toggle: check persistent global state
    local disabled_list = state.load_disabled_servers()
    local global_disabled_entry = "*:" .. server_name
    local is_globally_disabled = vim.tbl_contains(disabled_list, global_disabled_entry)

    if is_globally_disabled then
      -- Currently disabled globally -> enable globally
      M.enable_persistent(server_name, bufnr, true)
    else
      -- Currently enabled globally -> disable globally
      M.disable_persistent(server_name, bufnr, true)
    end
  else
    -- Project toggle: check if server should be enabled for this project
    local project_root = project.get_buffer_root(bufnr)
    local should_enable = M.should_be_enabled(server_name, project_root)

    if should_enable then
      -- Currently enabled for project -> disable for project
      M.disable_persistent(server_name, bufnr, false)
    else
      -- Currently disabled for project -> enable for project
      M.enable_persistent(server_name, bufnr, false)
    end
  end

  return true
end

return M
