local M = {}

function M.is_django_project(path)
  local markers = { "manage.py", "pyproject.toml" }
  local current = path

  -- Search up the directory tree for Django project markers
  while current ~= "/" do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(current .. "/" .. marker) == 1 then
        -- Check pyproject.toml for Django dependencies if that's the marker we found
        if marker == "pyproject.toml" then
          local content = vim.fn.readfile(current .. "/" .. marker)
          for _, line in ipairs(content) do
            if line:match("django") then
              return true
            end
          end
        else
          return true
        end
      end
    end
    current = vim.fn.fnamemodify(current, ":h")
  end
  return false
end

return M
