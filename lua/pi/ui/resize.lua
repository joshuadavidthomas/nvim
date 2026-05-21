local layout = require("pi.ui.layout")

local M = {}

local min_rows = 1
local max_rows = 10

--- Resize both windows based on the current input buffer line count.
---@param state pi.ui.State
---@param config pi.Config
function M.sync(state, config)
  local new_rows = math.max(min_rows, math.min(max_rows, vim.api.nvim_buf_line_count(state.input_buf)))
  if new_rows == state.current_input_rows then
    return
  end
  state.current_input_rows = new_rows
  local geo = layout.compute(config, new_rows)

  if vim.api.nvim_win_is_valid(state.display_win) then
    vim.api.nvim_win_set_config(state.display_win, {
      relative = "editor",
      row = geo.display.row,
      col = geo.display.col,
      width = geo.display.width,
      height = geo.display.height,
    })
  end

  if vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_win_set_config(state.input_win, {
      relative = "editor",
      row = geo.input.row,
      col = geo.input.col,
      width = geo.input.width,
      height = geo.input.height,
    })
    -- Reset scroll so all lines are visible when they fit
    local buf_lines = vim.api.nvim_buf_line_count(state.input_buf)
    if buf_lines <= new_rows then
      vim.api.nvim_win_call(state.input_win, function()
        vim.fn.winrestview({ topline = 1 })
      end)
    end
  end
end

--- Reset input to minimum size (call after clearing the buffer).
---@param state pi.ui.State
---@param config pi.Config
function M.reset(state, config)
  state.current_input_rows = 0
  M.sync(state, config)
end

return M
