local p = require("utils.path")

local M = {}

M.opened_to_dir = vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1
M.opened_to_file = vim.fn.argc(-1) == 0

--- Get a path in the Neovim config directory
--- @vararg string The parts of the path in the config dir.
--- @return string The joined path.
function M.config_path(...)
  return p.join(vim.fn.stdpath("config"), ...)
end

--- Get the start and end line numbers of the current selection in visual mode.
--- This function correctly handles the cases where the start line might
--- be below the end line, depending on cursor movements.
--- @return integer, integer: The start and end line numbers, respectively.
function M.get_start_end_lineno()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  return start_line, end_line
end

--- Set the value to a specific Vim register.
--- @param value string|nil: The value to set in the register.
--- @param register string?: The register to use (defaults to the system clipboard, "+").
function M.set_clipboard(value, register)
  vim.fn.setreg(register or "+", value)
end

---@param buffer number The buffer number to check
---@param exclude_filetypes? string[] Optional list of filetypes to exclude
---@return boolean valid Whether the buffer is valid and should be processed
function M.is_valid_buffer(buffer, exclude_filetypes)
  -- Skip invalid buffers, non-listed buffers, and special buffers
  if not vim.api.nvim_buf_is_valid(buffer) or not vim.bo[buffer].buflisted or vim.bo[buffer].buftype == "nofile" then
    return false
  end

  if exclude_filetypes and vim.tbl_contains(exclude_filetypes, vim.bo[buffer].filetype) then
    return false
  end

  return true
end

return M
