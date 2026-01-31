local servers = require("lsp.servers")
local state = require("lsp.state")
local project = require("utils.project")

local M = {}

-- Calculate checkbox state for server in picker
---@param server_name string Server name
---@param global boolean Whether this is global picker
---@param project_root string Project root path
---@param disabled_list table List of disabled entries
---@param enabled_list table List of enabled entries
---@return string Checkbox display ("[ ]", "[x]", or "[-]")
local function get_server_checkbox_state(server_name, global, project_root, disabled_list, enabled_list)
  if global then
    -- Global picker: show partial state for mixed enablement
    local is_disabled_global = vim.tbl_contains(disabled_list, "*:" .. server_name)
    if is_disabled_global then
      -- Check if ANY project has an enable override for this server
      local has_any_project_override = false
      for _, entry in ipairs(enabled_list) do
        if entry and entry:match(":([^:]+)$") == server_name then
          has_any_project_override = true
          break
        end
      end
      return has_any_project_override and "[-]" or "[ ]"
    else
      return "[x]"
    end
  else
    -- Project picker: checkbox shows if server should be enabled for this project
    local should_enable = servers.should_be_enabled(server_name, project_root)
    return should_enable and "[x]" or "[ ]"
  end
end

-- Launch server picker for toggling individual servers
function M.pick_server(bufnr, global)
  bufnr = bufnr or 0
  local filetype = vim.bo[bufnr].filetype

  if filetype == "" then
    vim.notify("No filetype detected for current buffer", vim.log.levels.WARN)
    return
  end

  local available = servers.get_servers(filetype)
  if #available == 0 then
    vim.notify(string.format("No LSP servers available for filetype: %s", filetype), vim.log.levels.WARN)
    return
  end

  local project_root = project.get_buffer_root(bufnr)
  local disabled_list = state.load_disabled_servers()
  local enabled_list = state.load_enabled_servers()

  local items = {}
  local idx = 1
  for _, server_name in ipairs(available) do
    if not server_name or server_name == "" then
      goto continue
    end

    local checkbox = get_server_checkbox_state(server_name, global, project_root, disabled_list, enabled_list)
    local display_text = string.format("%s %s", checkbox, server_name)

    table.insert(items, {
      formatted = display_text,
      text = idx .. " " .. display_text,
      server = server_name,
      idx = idx,
      item = display_text,
    })
    idx = idx + 1

    ::continue::
  end

  local scope = global and "Global" or "Project"

  -- Validate items before passing to picker
  if #items == 0 then
    vim.notify("No valid server items found", vim.log.levels.WARN)
    return
  end

  -- Create Snacks picker matching select format
  local Snacks = require("snacks")
  Snacks.picker.pick({
    source = "select",
    items = items,
    format = Snacks.picker.format.ui_select({}),
    title = string.format("%s LSP Servers (%s)", scope, filetype),
    layout = {
      preview = false,
      layout = {
        width = 50,
        min_width = 50,
        height = math.floor(math.min(vim.o.lines * 0.8 - 10, #items + 2) + 0.5),
      },
    },
    actions = {
      confirm = function(picker, item)
        picker:close()
        if item and item.server then
          servers.toggle_server(item.server, bufnr, global)
        end
      end,
    },
  })
end

return M
