local layout = require("pi.ui.layout")
local chrome = require("pi.ui.chrome")
local resize = require("pi.ui.resize")

local M = {}

---@class pi.ui.State
---@field display_buf number
---@field display_win number
---@field input_buf number
---@field input_win number
---@field line_count number
---@field current_input_rows number
---@field mode_timer uv_timer_t

---@type pi.ui.State|nil
local state = nil

local function get_state()
  return state
end

function M.is_open()
  return state ~= nil
end

---@param config pi.Config
function M.open(config)
  if state then
    return
  end

  local geo = layout.compute(config, 1)

  -- Buffers
  local display_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("modifiable", false, { buf = display_buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = display_buf })

  local input_buf = vim.api.nvim_create_buf(false, true)

  -- Windows
  local display_win = layout.open_float(display_buf, geo.display, "pi")
  vim.api.nvim_set_option_value("wrap", true, { win = display_win })
  vim.api.nvim_set_option_value("linebreak", true, { win = display_win })
  vim.api.nvim_set_option_value("cursorline", false, { win = display_win })
  vim.api.nvim_set_option_value("winhighlight", "FloatBorder:PiBorder,FloatTitle:PiTitle", { win = display_win })

  local input_win = layout.open_float(input_buf, geo.input, "ask")
  vim.api.nvim_set_option_value("wrap", true, { win = input_win })

  state = {
    display_buf = display_buf,
    display_win = display_win,
    input_buf = input_buf,
    input_win = input_win,
    line_count = 0,
    current_input_rows = 1,
  }

  -- Chrome (mode indicator + scroll)
  local function update_chrome()
    if state then
      chrome.update(state)
    end
  end

  state.mode_timer = chrome.start_mode_poll(get_state, update_chrome)
  update_chrome()

  -- Auto-resize + chrome on text/cursor changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CursorMoved", "CursorMovedI" }, {
    buffer = input_buf,
    callback = function()
      if state then
        resize.sync(state, config)
        chrome.update(state)
      end
    end,
  })

  -- Submit
  local function submit()
    if not state then
      return
    end
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    local value = table.concat(lines, "\n")
    if value ~= "" then
      vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })
      resize.reset(state, config)
      require("pi").send(value)
    end
  end
  vim.keymap.set({ "i", "n" }, "<C-CR>", submit, { buffer = input_buf, noremap = true })

  -- Close
  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, { buffer = input_buf, noremap = true })
  vim.keymap.set("n", "q", function()
    M.close()
  end, { buffer = input_buf, noremap = true })
  vim.keymap.set("i", "<C-c>", function()
    M.close()
  end, { buffer = input_buf, noremap = true })

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = input_buf,
    callback = function()
      vim.schedule(function()
        if state and vim.api.nvim_get_current_win() ~= state.display_win then
          M.close()
        end
      end)
    end,
  })

  -- Focus
  vim.api.nvim_set_current_win(input_win)
  vim.cmd("startinsert")
end

function M.close()
  if not state then
    return
  end
  local s = state
  state = nil

  if s.mode_timer then
    s.mode_timer:stop()
    s.mode_timer:close()
  end

  if vim.api.nvim_win_is_valid(s.input_win) then
    vim.api.nvim_win_close(s.input_win, true)
  end
  if vim.api.nvim_win_is_valid(s.display_win) then
    vim.api.nvim_win_close(s.display_win, true)
  end
  if vim.api.nvim_buf_is_valid(s.input_buf) then
    vim.api.nvim_buf_delete(s.input_buf, { force = true })
  end
  if vim.api.nvim_buf_is_valid(s.display_buf) then
    vim.api.nvim_buf_delete(s.display_buf, { force = true })
  end
end

---@param role "user"|"assistant"
---@param text string
function M.append_message(role, text)
  if not state then
    return
  end

  local prefix = role == "user" and "**You**: " or "**pi**: "
  local lines = vim.split(prefix .. text, "\n", { plain = true })

  if state.line_count > 0 then
    table.insert(lines, 1, "")
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = state.display_buf })
  vim.api.nvim_buf_set_lines(state.display_buf, state.line_count, state.line_count, false, lines)
  state.line_count = state.line_count + #lines
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.display_buf })

  if vim.api.nvim_win_is_valid(state.display_win) then
    vim.api.nvim_win_set_cursor(state.display_win, { state.line_count, 0 })
  end
end

---@param text string
function M.set_input(text)
  if not state then
    return
  end

  vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { text })

  if vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_set_current_win(state.input_win)
    vim.cmd("startinsert!")
  end
end

return M
