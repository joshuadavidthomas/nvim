local M = {}

---@param opts? {bufnr?: number, timeout_ms?: number}
function M.format(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local timeout_ms = opts.timeout_ms or 3000

  local ok, conform = pcall(require, "conform")
  if ok then
    local result = conform.format({ bufnr = bufnr, timeout_ms = timeout_ms })

    if result then
      return
    end
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })

  if #clients > 0 then
    vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = timeout_ms })
  else
    vim.notify("No formatting providers available for this buffer", vim.log.levels.WARN)
  end
end

local DISABLED_PROJECTS_PATH = vim.fn.stdpath("data") .. "/format_disabled_projects"

local function load_disabled_projects()
  local file = io.open(DISABLED_PROJECTS_PATH, "r")
  if not file then
    return {}
  end
  local projects = {}
  for line in file:lines() do
    line = vim.trim(line)
    if line ~= "" then
      table.insert(projects, line)
    end
  end
  file:close()
  return projects
end

local function save_disabled_projects(projects)
  local file = io.open(DISABLED_PROJECTS_PATH, "w")
  if not file then
    vim.notify("Failed to save format disabled projects", vim.log.levels.ERROR)
    return
  end
  for _, project in ipairs(projects) do
    file:write(project .. "\n")
  end
  file:close()
end

-- Project-specific formatting control
M.projects = {}

-- Get current project root
function M.projects.get_current_project()
  local git = require("utils.git")
  local path = vim.fn.expand("%:p")
  return git.find_git_ancestor(path) or vim.fn.getcwd()
end

-- Check if formatting is disabled for current project
function M.projects.is_disabled(path)
  local git = require("utils.git")
  local project_root = git.find_git_ancestor(path) or vim.fn.getcwd()
  local disabled_projects = load_disabled_projects()
  return vim.tbl_contains(disabled_projects, project_root)
end

-- Get formatting state for current project
function M.projects.get()
  local path = vim.fn.expand("%:p")
  return not M.projects.is_disabled(path)
end

-- Set formatting state for current project
function M.projects.set(enabled)
  local project_root = M.projects.get_current_project()
  local disabled_projects = load_disabled_projects()

  local new_projects = {}
  for _, project in ipairs(disabled_projects) do
    if project ~= project_root then
      table.insert(new_projects, project)
    end
  end

  if not enabled then
    table.insert(new_projects, project_root)
  end

  save_disabled_projects(new_projects)
end

-- List all projects with disabled formatting
function M.projects.list()
  local disabled_projects = load_disabled_projects()
  if #disabled_projects == 0 then
    vim.notify("No projects have formatting disabled", vim.log.levels.INFO)
    return
  end

  local git = require("utils.git")
  local current_path = vim.fn.expand("%:p")
  local current_project = git.find_git_ancestor(current_path) or vim.fn.getcwd()

  local lines = { "Projects with formatting disabled:" }
  for _, project in ipairs(disabled_projects) do
    local marker = project == current_project and " (current)" or ""
    table.insert(lines, "  • " .. project .. marker)
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
