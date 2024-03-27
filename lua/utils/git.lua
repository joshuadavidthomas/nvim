local M = {}

function M.relative_git_command(command, to_file)
  local dir_path = vim.fn.shellescape(vim.fn.fnamemodify(to_file, ":h"), 1)
  return vim.fn.system("git -C " .. dir_path .. " " .. command)
end

local cache = {}

function M.in_git_repo(buffer)
  if not vim.fn.filereadable(buffer) == 1 then
    return false
  end

  if cache[buffer] ~= nil then
    return cache[buffer]
  end

  local in_git_repo = M.relative_git_command("rev-parse --is-inside-work-tree", buffer):match("true")
  cache[buffer] = in_git_repo
  return in_git_repo
end

function M.gh_permalink(file)
  local origin_url = M.relative_git_command("config --get remote.origin.url"):gsub("%.git\n?$", "")

  if origin_url:match("github.com") then
    local base_url

    if origin_url:match("^git@") then
      local username_repo = origin_url:gsub("^git@github.com:", "")
      base_url = "https://github.com/" .. username_repo
    elseif origin_url:match("^https://") then
      base_url = origin_url:match("(https://github.com/[^/]+/[^/]+)")
    end

    local commit_hash = M.relative_git_command("rev-parse HEAD"):gsub("\n", "")
    local relative_filepath = M.relative_git_command("ls-files --full-name " .. vim.fn.shellescape(file)):gsub("\n", "")

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

function M.copy_gh_permalink()
  local buffer_path = vim.fn.expand("%:p")

  if M.in_git_repo(buffer_path) then
    local permalink_func = M.gh_permalink
    local is_visual_mode = vim.fn.mode():match("[vV]")

    if is_visual_mode then
      permalink_func = M.gh_permalink_lineno
    end

    vim.fn.setreg("+", permalink_func(buffer_path))

    if is_visual_mode then
      vim.api.nvim_input("<Esc>")
    end

    vim.notify("Copied permalink to clipboard")
  end
end

return M
