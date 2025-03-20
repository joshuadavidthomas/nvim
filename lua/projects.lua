local M = {}

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
  })
end

return M
