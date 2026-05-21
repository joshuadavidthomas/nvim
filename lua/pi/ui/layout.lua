local M = {}

---@class pi.ui.Geometry
---@field display { row: number, col: number, width: number, height: number }
---@field input { row: number, col: number, width: number, height: number }

---@param config pi.Config
---@param input_rows number
---@return pi.ui.Geometry
function M.compute(config, input_rows)
  local width = config.width
  local height = config.height
  local editor_w = vim.o.columns
  local editor_h = vim.o.lines - vim.o.cmdheight

  local input_h = input_rows + 2 -- +2 for border
  local display_h = height - input_h
  local inner_w = width - 2 -- -2 for border

  local col = math.floor((editor_w - width) / 2)
  local row = math.floor((editor_h - height) / 2)

  return {
    display = { row = row, col = col, width = inner_w, height = display_h - 2 },
    input = { row = row + display_h, col = col, width = inner_w, height = input_rows },
  }
end

---@param buf number
---@param geo { row: number, col: number, width: number, height: number }
---@param title string
---@return number winid
function M.open_float(buf, geo, title)
  return vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = geo.row,
    col = geo.col,
    width = geo.width,
    height = geo.height,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "left",
  })
end

return M
