---@class Projects
local M = {}

---@class ProjectConfig
---@field markers string[] List of marker files to identify project type
---@field validate? table<string, fun(file_path: string): boolean> Optional validation functions for markers

---@type table<string, ProjectConfig>
local project_types = {}

---Register a project type
---@param name string The name of the project type
---@param markers string[] List of marker files to identify this project type
---@param validate? table<string, fun(file_path: string): boolean> Optional validation functions for markers
function M.register(name, markers, validate)
  project_types[name] = {
    markers = markers,
    validate = validate or {},
  }
end

---Check if a path is a specific project type
---@param project_type string The type of project to check for
---@param path string The directory path to check
---@return boolean is_project_type, table? metadata
function M.is_project(project_type, path)
  local config = project_types[project_type]
  if not config then
    return false
  end

  local markers = config.markers
  local validate = config.validate or {}
  local current = path

  -- Search up the directory tree for project markers
  while current ~= "/" do
    for _, marker in ipairs(markers) do
      local marker_path = current .. "/" .. marker
      if vim.fn.filereadable(marker_path) == 1 then
        -- If there's a validation function for this marker, use it
        if validate[marker] then
          local result = validate[marker](marker_path)
          if type(result) == "table" then
            return true, result
          elseif result then
            return true
          end
        else
          -- No validation needed, marker's presence is enough
          return true
        end
      end
    end
    current = vim.fn.fnamemodify(current, ":h")
  end
  return false
end

---Check if current working directory is a specific project type
---@param project_type string The type of project to check for
---@return boolean is_project_type
function M.is_cwd_project(project_type)
  return M.is_project(project_type, vim.fn.getcwd())
end

---Check if a buffer's directory is a specific project type
---@param project_type string The type of project to check for
---@param bufnr? number Buffer number (defaults to current buffer)
---@return boolean is_project_type
function M.is_buffer_project(project_type, bufnr)
  bufnr = bufnr or 0
  local buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
  return M.is_project(project_type, buf_path)
end

return M
