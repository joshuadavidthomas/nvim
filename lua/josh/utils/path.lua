-- Portions of this file were copied or adapted from https://github.com/neovim/nvim-lspconfig
-- nvim-lspconfig is Copyright Neovim contributors and is licensed under the Apache 2.0 license.
-- A copy of the Apache 2.0 license can be found in `.config/nvim/.licenses/`.

local uv = vim.uv

--- Check if the operating system is Windows.
local is_windows = uv.os_uname().version:match("Windows")

local M = {}

--- Escape wildcard characters in a filesystem path.
--- @param path string The path to sanitize.
--- @return string The sanitized path with wildcards escaped.
function M.escape_wildcards(path)
  local escaped_path = path:gsub("([%[%]%?%*])", "\\%1")
  return escaped_path
end

--- Sanitize a filesystem path based on the operating system.
--- @param path string The path to sanitize.
--- @return string The sanitized path, with appropriate path separators and casing for Windows.
function M.sanitize(path)
  if is_windows then
    path = path:sub(1, 1):upper() .. path:sub(2)
    path = path:gsub("\\", "/")
  end
  return path
end

--- Check if a file or directory exists and return its type or false if it doesn't exist.
--- @param filename string The filename or directory path to check.
--- @return string|false The type of the file system object ('file', 'directory', etc.) or false if not found.
function M.exists(filename)
  local stat = uv.fs_stat(filename)
  return stat and stat.type or false
end

--- Determine if a specified path is a directory.
--- @param filename string The path to check.
--- @return boolean True if the path is a directory, false otherwise.
function M.is_dir(filename)
  return M.exists(filename) == "directory"
end

--- Determine if a specified path is a file.
--- @param filename string The path to check.
--- @return boolean True if the path is a file, false otherwise.
function M.is_file(filename)
  return M.exists(filename) == "file"
end

--- Check if a path is the filesystem root.
--- @param path string The path to check.
--- @return boolean True if the path is the root of the filesystem, false otherwise.
function M.is_fs_root(path)
  if is_windows then
    return path:match("^%a:$")
  else
    return path == "/"
  end
end

--- Determine if a specified path is an absolute path.
--- @param filename string The path to check.
--- @return boolean True if the path is absolute, false otherwise.
function M.is_absolute(filename)
  if is_windows then
    return filename:match("^%a:") or filename:match("^\\\\")
  else
    return filename:match("^/")
  end
end

function M.parts(path)
  local parts = {}
  for part in M.sanitize(path):gmatch("[^/\\]+") do
    table.insert(parts, part)
  end
  return parts
end

--- Calculate the relative path from one directory to another.
--- @param from string: The starting directory path, expected to be an absolute path.
--- @param to string: The target directory path, expected to be an absolute path.
--- @return string: The relative path from `from` to `to`. If `from` and `to` are the same, returns an empty string.
function M.relative(from, to)
  local fromParts = M.parts(from)
  local toParts = M.parts(to)

  -- Find the common root and determine how many levels up from 'from' path
  local length = math.min(#fromParts, #toParts)
  local commonLength = 0
  for i = 1, length do
    if fromParts[i] == toParts[i] then
      commonLength = i
    else
      break
    end
  end

  -- Build the relative path
  local relativeParts = {}
  for _ = 1, #fromParts - commonLength do
    table.insert(relativeParts, "..")
  end
  for i = commonLength + 1, #toParts do
    table.insert(relativeParts, toParts[i])
  end

  return table.concat(relativeParts, "/")
end

--- Get the directory part of a path, removing the last segment.
--- @generic T: string?
--- @param path T The full path from which to extract the directory part.
--- @return T The directory part of the path or the same value if it's nil or empty.
function M.dirname(path)
  if not path or #path == 0 then
    return path
  end
  local strip_dir_pat = "/([^/]+)$"
  local strip_sep_pat = "/$"
  local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
  if #result == 0 then
    if is_windows then
      return path:sub(1, 2):upper()
    else
      return "/"
    end
  end
  return result
end

--- Join multiple parts of a path into a single path string.
--- @vararg string The parts of the path to join.
--- @return string The joined path.
function M.join(...)
  local parts = vim.tbl_flatten({ ... })
  -- Strip trailing slash, if exists
  for i, part in ipairs(parts) do
    parts[i] = part:gsub("/+$", "")
  end
  return table.concat(parts, "/")
end

--- Path separator based on the operating system.
M.path_separator = is_windows and ";" or ":"

--- Join multiple path segments from a table into a single path string.
--- @param paths table: A table (array) of strings, each representing a path segment.
--- @return string: The resulting path after concatenating all provided segments from the table with the OS-specific path separator.
function M.join_paths(paths)
  return table.concat(vim.tbl_flatten(paths), M.path_separator)
end

--- Search ancestor directories starting from a specified path and apply a given function to each until the function returns true.
--- @param startpath string The starting path from which to search ancestor directories.
--- @param func function The function to apply to each ancestor directory. Should return true to stop the search.
--- @return string|nil The path of the first ancestor directory for which the function returns true, or nil if none do.
function M.search_ancestors(startpath, func)
  vim.validate({ func = { func, "f" } })
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in M.iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

--- Iterate through parent directories of a given path until a specified endpoint or the root is found.
--- @param path string: The path from which to start iteration.
--- @return function, string, string An iterator function, the initial state, and the initial value for the iteration.
function M.iterate_parents(path)
  local function it(_, v)
    if v and not M.is_fs_root(v) then
      v = M.dirname(v)
    else
      return
    end
    if v and uv.fs_realpath(v) then
      return v, path
    else
      return
    end
  end
  return it, path, path
end

--- Check if one path is a descendant of another.
--- @param root string The root path to check against.
--- @param path string The path that may be a descendant.
--- @return boolean True if the path is a descendant of the root, false otherwise.
function M.is_descendant(root, path)
  if not path then
    return false
  end

  local function cb(dir, _)
    return dir == root
  end

  local dir, _ = M.search_ancestors(path, cb)

  return dir == root
end

--- Convert a buffer identifier to its full path.
--- @param buffer number|string Buffer identifier or buffer name
--- @return string The full filesystem path of the directory containing the buffer
function M.buffer_to_path(buffer)
  -- Expand the buffer to a full path and extract the directory part
  local full_path = vim.fn.expand("#" .. buffer .. ":p")
  return M.dirname(full_path)
end

function M.platformdirs(app)
  local home = vim.env.HOME
  local user_data_dir = vim.env.XDG_DATA_HOME or M.join(home, ".local", "share")
  local user_config_dir = vim.env.XDG_CONFIG_HOME or M.join(home, ".config")
  local user_cache_dir = vim.env.XDG_CACHE_HOME or M.join(home, ".cache")
  local user_state_dir = vim.env.XDG_STATE_HOME or M.join(home, ".local", "state")
  local site_data_dir = vim.env.XDG_DATA_DIR
  local site_config_dir = (function()
    local dirs = vim.env.XDG_CONFIG_DIRS
    if not dirs then
      dirs = { "/etc/xdg" }
    end
    local config_dirs = {}
    for _, value in ipairs(dirs) do
      table.insert(config_dirs, M.join(value, app))
    end
    return M.join_paths(config_dirs)
  end)()
  local site_cache_dir = "/var/cache"
  return {
    home = home,
    user_data_dir = M.join(user_data_dir, app),
    user_config_dir = M.join(user_config_dir, app),
    user_cache_dir = M.join(user_cache_dir, app),
    user_state_dir = M.join(user_state_dir, app),
    site_data_dir = M.join(site_data_dir, app),
    site_config_dir = site_config_dir[1],
    site_cache_dir = M.join(site_cache_dir, app),
  }
end

--- Determine if a file should be hidden, optionally considering .gitignore patterns if in a Git repository.
--- @param name string: The name of the file to check.
--- @param current_dir string?: The name of the current directory.
--- @return boolean True if the file should be hidden, false otherwise.
function M.is_hidden_file(name, current_dir)
  if vim.startswith(name, ".") then
    return true
  end

  local cwd = current_dir or vim.fn.fnamemodify(name, ":p:h")
  local gitignore_patterns = require("josh.utils.git").get_gitignore_patterns(cwd)
  if gitignore_patterns then
    for _, pattern in ipairs(gitignore_patterns) do
      if pattern ~= "" then
        local prepared_pattern = pattern
        if pattern:sub(-1) == "/" then
          prepared_pattern = pattern:sub(1, -2)
        end
        local regex_pattern = vim.fn.glob2regpat(prepared_pattern)
        if vim.fn.match(name, regex_pattern) ~= -1 then
          return true
        end
      end
    end
  end

  return false
end

return M
