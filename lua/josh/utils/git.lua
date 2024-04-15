local f = require("josh.utils.file")
local p = require("josh.utils.path")
local s = require("josh.utils.string")
local v = require("josh.utils.vim")

local M = {}

--- Find the closest git repository ancestor directory.
--- This function was copied and adapted from https://github.com/neovim/nvim-lspconfig
--- nvim-lspconfig is Copyright Neovim contributors and is licensed under the Apache 2.0 license.
--- A copy of the Apache 2.0 license can be found in `.config/nvim/.licenses/`.
--- @param startpath string: The starting file or directory path to search for a git ancestor.
--- @return string|nil: The path to the closest git repository ancestor, or nil if not found.
function M.find_git_ancestor(startpath)
  return p.search_ancestors(startpath, function(path)
    local git_dir = M.get_git_dir(path)
    if git_dir then
      return path
    end
  end)
end

--- Check if a given path is within a git repository.
--- @param path string: The path of the file or directory.
--- @return boolean: Returns true if the path is within a git repository, false otherwise.
function M.in_git_repo(path)
  return M.find_git_ancestor(path) ~= nil
end

--- Get the .git directory of a git repository.
--- @param git_root string: The root directory of a git repository.
--- @retunr string|nil: The path of the .git directory, or nil if not found or not applicable.
function M.get_git_dir(git_root)
  local git_dir = p.join(git_root, ".git")
  if p.is_dir(git_dir) or p.is_file(git_dir) then
    return git_dir
  end
end

--- Get the .git directory of a git repository of a file path.
--- @param path string: The path of the file.
--- @retunr string|nil: The path of the .git directory, or nil if not found or not applicable.
function M.find_git_dir(path)
  local git_root = M.find_git_ancestor(path)
  if git_root then
    local git_dir = M.get_git_dir(git_root)
    if git_dir then
      return git_dir
    end
  end
end

--- Executes a Git command relative to the directory of the specified file.
--- @param command string: The Git command to execute.
--- @param to_file string: The path to the file relative to which the Git command should be executed.
--- @return string: The output from the executed command.
function M.relative_git_command(command, to_file)
  local dir_path = vim.fn.shellescape(vim.fn.fnamemodify(to_file, ":h"), 1)
  return vim.fn.system("git -C " .. dir_path .. " " .. command)
end

--- Parse a .gitignore file and return a table of all patterns contained within it.
--- @param gitignore string: The path of the .gitignore file.
--- @return table: A table of patterns from the .gitignore file.
function M.parse_gitignore(gitignore)
  local patterns = {}
  local line_count = 0
  for line in io.lines(gitignore) do
    line_count = line_count + 1
    line = line:gsub("%s+$", "")
    if line ~= "" and line:sub(1, 1) ~= "#" then
      table.insert(patterns, line)
    end
  end
  return patterns
end

--- Parse a git config and return a table of all config options contained within it.
--- @param git_config string: The path of the git config file.
--- @return table: A table of the config options from the git config file.
function M.parse_git_config(git_config)
  local config = {}
  local section
  local subname
  for line in io.lines(git_config) do
    if line:match("^%[") then
      section, subname = line:match('^%[([%w]+)%s*"?([%w_-]*)"?%]$')
      if subname and subname ~= "" then
        if not config[section] then
          config[section] = {}
        end
        config[section][subname] = {}
        section = config[section][subname]
      else
        config[section] = {}
        section = config[section]
      end
    elseif line:match("^%s*[%w]") then
      local key, value = line:match("^%s*([^=]+)%s*=%s*(.+)%s*$")
      if key and value then
        key = s.trim(key)
        value = s.trim(value)
        section[key] = value
      end
    end
  end
  return config
end

--- Read and parse the .gitignore file associated with a file's git repository.
--- @param startpath string: The path of the file.
--- @return table|nil: A table of patterns from the .gitignore file, or nil if not found or not applicable.
function M.get_gitignore_patterns(startpath)
  local git_root = M.find_git_ancestor(startpath)
  if git_root then
    local patterns = {}
    p.search_ancestors(startpath, function(path)
      local gitignore_path = p.join(path, ".gitignore")
      if p.is_file(gitignore_path) then
        local ignore_patterns = M.parse_gitignore(gitignore_path)
        for _, pattern in ipairs(ignore_patterns) do
          table.insert(patterns, pattern)
        end
        return path == git_root
      end
    end)
    return patterns
  end
end

--- Read and parse the .git/config file associated with a file's git repository.
--- @param path string: The path of the file.
--- @return table|nil: The parsed git config as a nested table, or nil if not found or unreadable.
function M.get_git_config(path)
  -- TODO: add global config? right now this is just used to grab the remote urls for `M.get_remote_url`
  -- but it could be useful to include the global git config in ~/.config/git/config as well. i'll wait until
  -- a need arises before tackling that.
  local git_root = M.find_git_ancestor(path)
  if git_root then
    local git_dir = M.find_git_dir(path)
    if git_dir then
      local git_config_path = p.join(git_dir, "config")
      if p.is_file(git_config_path) then
        return M.parse_git_config(git_config_path)
      end
    end
  end
end

--- Retrieve the URL of a specified git remote from the cached git config.
--- @param path string: The path of the file.
--- @param remote_name string: The name of the remote whose URL is needed.
--- @return string|nil: The URL of the specified remote, or nil if not found.
function M.get_remote_url(path, remote_name)
  local config = M.get_git_config(path)
  if config then
    local remote = config.remote
    if remote or remote[remote_name] then
      local remote_config = remote[remote_name]
      if remote_config or remote_config.url then
        return remote_config.url
      end
    end
  end
end

--- Get the current commit SHA
--- @param path string: The path of the file.
--- @return string|nil: The full SHA of the commit hash, or nil if not found.
function M.get_current_commit_sha(path)
  local git_dir = M.find_git_dir(path)
  if git_dir then
    local head_path = p.join(git_dir, "HEAD")
    local head_content = f.read_file(head_path)
    if head_content then
      -- check for SHA hash directly
      head_content = string.gsub(head_content, "%s+", "")
      if string.match(head_content, "^%x+$") and #head_content == 40 then
        return head_content
      end
      local head_ref = string.match(head_content, "ref:([^%s]+)")
      local ref_path = p.join(git_dir, head_ref)
      local ref_content = f.read_file(ref_path)
      if ref_content then
        local cleaned_content = string.gsub(ref_content, "%s+", "")
        return cleaned_content
      end
    end
  end
end

--- Compute the relative path of a file within its Git repository.
--- @param path string: The absolute path to the file.
--- @return string|nil: The relative path of the file within its Git repository, or nil if not within a repository.
function M.get_relative_filepath(path)
  local git_root = M.find_git_ancestor(path)
  if git_root then
    return path:sub(#git_root + 2)
  end
end

--- Generate a GitHub permalink for a specific file based on the current HEAD commit.
--- @param file string: The local file path relative to the git repository root.
--- @return string|nil: The GitHub permalink URL, or nil if not applicable.
function M.gh_permalink(file)
  local origin_url = M.get_remote_url(file, "origin"):gsub("%.git\n?$", "")
  if origin_url:match("github.com") then
    local commit_hash = M.get_current_commit_sha(file)
    local relative_filepath = M.get_relative_filepath(file)
    local base_url
    if origin_url:match("^git@") then
      local username_repo = origin_url:gsub("^git@github.com:", "")
      base_url = "https://github.com/" .. username_repo
    elseif origin_url:match("^https://") then
      base_url = origin_url:match("(https://github.com/[^/]+/[^/]+)")
    end
    if not base_url and not commit_hash and not relative_filepath then
      return nil
    end
    local permalink = base_url .. "/blob/" .. commit_hash .. "/" .. relative_filepath
    local is_visual_mode = vim.fn.mode():match("[vV]")
    if is_visual_mode then
      local start_line, end_line = v.get_start_end_lineno()
      permalink = permalink .. "#L" .. start_line .. "-L" .. end_line
    end
    return permalink
  end
end

--- Copy a GitHub permalink to the system clipboard, with line number support for visual mode selections.
function M.copy_gh_permalink()
  local buffer_path = vim.fn.expand("%:p")
  if M.in_git_repo(buffer_path) then
    local permalink = M.gh_permalink(buffer_path)
    v.set_clipboard(permalink)
    local is_visual_mode = vim.fn.mode():match("[vV]")
    if is_visual_mode then
      vim.api.nvim_input("<Esc>")
    end
    vim.notify("Copied permalink to clipboard:\n\n" .. permalink)
  end
end

return M
