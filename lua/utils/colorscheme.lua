local M = {}

M.default = "tokyonight"
M.state_path = vim.fn.stdpath("state") .. "/colorscheme"

function M.read(default)
  if vim.fn.filereadable(M.state_path) ~= 1 then
    return default or M.default
  end

  local lines = vim.fn.readfile(M.state_path)
  local colorscheme = vim.trim(lines[1] or "")

  if colorscheme == "" then
    return default or M.default
  end

  return colorscheme
end

function M.write(colorscheme)
  if not colorscheme or colorscheme == "" then
    return
  end

  vim.fn.mkdir(vim.fn.fnamemodify(M.state_path, ":h"), "p")
  vim.fn.writefile({ colorscheme }, M.state_path)
end

return M
