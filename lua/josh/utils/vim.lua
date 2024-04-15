local M = {}

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
  register = register or "+"
  vim.fn.setreg(register, value)
end

return M
