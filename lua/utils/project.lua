local M = {}

-- Project root cache for buffers
local cache = {}

-- Get project root for a file path
function M.get_path_root(path)
  local git = require("utils.git")
  path = path or vim.fn.expand("%:p")
  return git.find_git_ancestor(path) or vim.fn.getcwd()
end

-- Get project root for a buffer (always cached)
function M.get_buffer_root(bufnr)
  bufnr = bufnr or 0

  if cache[bufnr] then
    return cache[bufnr]
  end

  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  local path = buf_path ~= "" and buf_path or vim.fn.expand("%:p")
  local root = M.get_path_root(path)

  cache[bufnr] = root
  return root
end

-- Clean up cache when buffer is deleted
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    local bufnr = args.buf
    cache[bufnr] = nil
  end,
})

return M
