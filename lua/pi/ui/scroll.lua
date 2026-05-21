local M = {}

---@class pi.scroll.Info
---@field hidden_above number lines hidden above the visible area
---@field hidden_below number lines hidden below the visible area
---@field has_overflow boolean true if any lines are hidden

--- Get scroll overflow info for a window.
---@param winid number
---@return pi.scroll.Info
function M.get_info(winid)
  local topline = vim.fn.getwininfo(winid)[1].topline
  local buf = vim.api.nvim_win_get_buf(winid)
  local buf_lines = vim.api.nvim_buf_line_count(buf)
  local win_height = vim.api.nvim_win_get_height(winid)
  local hidden_above = topline - 1
  local hidden_below = math.max(0, buf_lines - (topline + win_height - 1))

  return {
    hidden_above = hidden_above,
    hidden_below = hidden_below,
    has_overflow = hidden_above > 0 or hidden_below > 0,
  }
end

--- Format scroll info as a display string.
---@param info pi.scroll.Info
---@return string|nil
function M.format(info)
  if not info.has_overflow then
    return nil
  end

  local parts = {}
  if info.hidden_above > 0 then
    table.insert(parts, "▲ " .. info.hidden_above)
  end
  if info.hidden_below > 0 then
    table.insert(parts, "▼ " .. info.hidden_below)
  end

  return table.concat(parts, "  ")
end

return M
