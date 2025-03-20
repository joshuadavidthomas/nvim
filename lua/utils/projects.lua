---@class Projects
local M = {}

---Set up treesitter injections for 11ty template engines in markdown files
---@param bufnr number Buffer number
---@param engine string Template engine name
function M.setup_11ty_injections(bufnr, engine)
  -- Map of template engines to treesitter language names
  local engine_to_lang = {
    njk = "nunjucks",
    liquid = "liquid",
    hbs = "handlebars",
    handlebars = "handlebars",
    mustache = "mustache",
    ejs = "ejs",
    haml = "haml",
    pug = "pug",
  }
  
  local lang = engine_to_lang[engine] or engine
  
  -- Only proceed if we have a valid language mapping
  if not lang then return end
  
  -- Ensure the parser is available
  local parser_ok, _ = pcall(vim.treesitter.language.add, lang)
  if not parser_ok then
    vim.notify("Treesitter parser for " .. lang .. " not available", vim.log.levels.WARN)
    return
  end
  
  -- Create a custom injection query for markdown files with template language
  local query = string.format([[
    ;; Inject template language into fenced code blocks with matching language
    ((fenced_code_block
      (info_string) @_lang
      (code_fence_content) @injection.content)
     (#eq? @_lang "%s")
     (#set! injection.language "%s"))
    
    ;; Inject template language into template tags
    ((inline) @injection.content
     (#lua-match? @injection.content "{[%%{#]")
     (#set! injection.language "%s"))
    
    ;; Handle front matter
    ((front_matter) @injection.content
     (#set! injection.language "yaml")
     (#offset! @injection.content 1 0 -1 0)
     (#set! injection.include-children))
  ]], lang, lang, lang)
  
  -- Register the query with treesitter
  vim.treesitter.query.set("markdown", "injections-" .. bufnr, query)
  
  -- Store the query in a buffer variable so it persists
  vim.b[bufnr].eleventy_injection_query = query
  
  -- Force treesitter to reparse the buffer
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("TSBufEnable highlight")
  end)
end

---@class ProjectConfig
---@field markers string[] List of marker files to identify project type
---@field validate? table<string, fun(file_path: string): boolean, table?> Optional validation functions for markers

---@type table<string, ProjectConfig>
local project_types = {}

---Register a project type
---@param name string The name of the project type
---@param markers string[] List of marker files to identify this project type
---@param validate? table<string, fun(file_path: string): boolean, table?> Optional validation functions for markers
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
          local is_valid, metadata = validate[marker](marker_path)
          if is_valid then
            return true, metadata
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
