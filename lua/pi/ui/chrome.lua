local scroll = require("pi.ui.scroll")

local M = {}

local mode_labels = {
  n = "normal",
  i = "insert",
  v = "visual",
  V = "visual",
  ["\22"] = "visual",
  R = "replace",
  c = "command",
}

--- Update the input window's title and border to reflect the current mode
--- and scroll position.
---@param state pi.ui.State
function M.update(state)
  if not vim.api.nvim_win_is_valid(state.input_win) then
    return
  end

  local label = mode_labels[vim.fn.mode():sub(1, 1)] or "normal"
  local border_hl = "PiModeBorder_" .. label
  local title_hl = "PiModeTitle_" .. label

  local title = { { " " .. label .. " ", title_hl } }
  local scroll_text = scroll.format(scroll.get_info(state.input_win))
  if scroll_text then
    table.insert(title, { " " .. scroll_text .. " ", border_hl })
  end

  vim.api.nvim_win_set_config(state.input_win, {
    title = title,
    title_pos = "right",
    footer = "",
  })
  vim.api.nvim_set_option_value("winhighlight", "FloatBorder:" .. border_hl, { win = state.input_win })
end

--- Start a timer that polls the mode and updates chrome when it changes.
--- Returns the timer handle for cleanup.
---@param state_fn fun(): pi.ui.State|nil accessor to get current state
---@param on_change fun() called when mode changes
---@return uv_timer_t
function M.start_mode_poll(state_fn, on_change)
  local last_mode = ""
  local timer = vim.uv.new_timer()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      local s = state_fn()
      if not s then
        timer:stop()
        timer:close()
        return
      end
      local mode = vim.fn.mode():sub(1, 1)
      if mode ~= last_mode then
        last_mode = mode
        on_change()
      end
    end)
  )
  return timer
end

return M
