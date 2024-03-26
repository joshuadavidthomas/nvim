local M = {}

function M.git_command(command, relative_to_file)
  local dir_path = vim.fn.shellescape(vim.fn.fnamemodify(relative_to_file, ":h"), 1)
  return vim.fn.system("git -C " .. dir_path .. " " .. command)
end

local cache = {}

function M.is_in_git_repo(buffer)
  if not vim.fn.filereadable(buffer) == 1 then
    return false
  end

  if cache[buffer] ~= nil then
    return cache[buffer]
  end

  local in_git_repo = M.git_command("rev-parse --is-inside-work-tree", buffer):match("true")
  cache[buffer] = in_git_repo
  return in_git_repo
end

function M.gh_permalink(file)
  local origin_url = M.git_command("config --get remote.origin.url"):gsub("%.git\n?$", "")

  if origin_url:match("github.com") then
    local base_url

    if origin_url:match("^git@") then
      local username_repo = origin_url:gsub("^git@github.com:", "")
      base_url = "https://github.com/" .. username_repo
    elseif origin_url:match("^https://") then
      base_url = origin_url:match("(https://github.com/[^/]+/[^/]+)")
    end

    local commit_hash = M.git_command("rev-parse HEAD"):gsub("\n", "")
    local relative_filepath = M.git_command("ls-files --full-name " .. vim.fn.shellescape(file)):gsub("\n", "")

    if base_url then
      return base_url .. "/blob/" .. commit_hash .. "/" .. relative_filepath
    end
  end
end

function M.gh_permalink_lineno(file)
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  return M.gh_permalink(file) .. "#L" .. start_line .. "-L" .. end_line
end

return M
