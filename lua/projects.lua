local M = {}

-- Detect the template engines used in an Eleventy project
-- @param config_path string Path to the Eleventy config file
-- @return table Template engines configuration
function M.detect_eleventy_template_engines(config_path)
  local content = vim.fn.readfile(config_path)
  local engines = {
    html = "njk", -- Default to njk for HTML
    markdown = "njk", -- Default to njk for Markdown
  }

  for _, line in ipairs(content) do
    -- Look for htmlTemplateEngine setting
    local html_engine = line:match("htmlTemplateEngine%s*:%s*[\"']([^\"']+)[\"']")
    if html_engine then
      engines.html = html_engine
    end

    -- Look for markdownTemplateEngine setting
    local md_engine = line:match("markdownTemplateEngine%s*:%s*[\"']([^\"']+)[\"']")
    if md_engine then
      engines.markdown = md_engine
    end
  end

  return engines
end

function M.setup()
  local projects = require("utils.projects")

  projects.register("django", { "manage.py", "pyproject.toml" }, {
    ["pyproject.toml"] = function(file_path)
      local content = vim.fn.readfile(file_path)
      for _, line in ipairs(content) do
        if line:match("django") then
          return true
        end
      end
      return false
    end,
  })

  projects.register("11ty", {
    ".eleventy.js",
    "eleventy.config.js",
    "eleventy.config.mjs",
    "eleventy.config.cjs",
  }, {
    [".eleventy.js"] = function(file_path)
      return true, M.detect_eleventy_template_engines(file_path)
    end,
    ["eleventy.config.js"] = function(file_path)
      return true, M.detect_eleventy_template_engines(file_path)
    end,
    ["eleventy.config.mjs"] = function(file_path)
      return true, M.detect_eleventy_template_engines(file_path)
    end,
    ["eleventy.config.cjs"] = function(file_path)
      return true, M.detect_eleventy_template_engines(file_path)
    end,
  })
end

return M
