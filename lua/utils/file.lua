local uv = vim.loop

local M = {}

--- Read the contents of a file and return it.
--- @param path string: The path to the file.
--- @return string|nil: The contents of the file or nil if an error occurred.
function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

--- Get a timestamp of when a file was last modified.
--- @param path string: The path to the file.
--- @return number|nil: The last modification time as a Unix timestamp, or nil if an error occurred.
function M.get_last_modified_time(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return nil
  end
  return stat.mtime.sec -- Accessing the `sec` field of the `mtime` table
end

return M
