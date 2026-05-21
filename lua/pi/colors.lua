local M = {}

M.modes = { "normal", "insert", "visual", "replace", "command" }

--- Define Pi highlight groups from the tokyonight palette.
--- Call this on ColorScheme changes so they stay in sync.
function M.setup()
  local ok, colors = pcall(function()
    return require("tokyonight.colors").setup()
  end)

  if not ok then
    -- Fallback: link to built-in groups
    vim.api.nvim_set_hl(0, "PiBorder", { link = "FloatBorder" })
    vim.api.nvim_set_hl(0, "PiTitle", { link = "FloatTitle" })
    for _, label in ipairs(M.modes) do
      vim.api.nvim_set_hl(0, "PiModeBorder_" .. label, { link = "FloatBorder" })
      vim.api.nvim_set_hl(0, "PiModeTitle_" .. label, { link = "FloatTitle" })
    end
    return
  end

  local black = colors.black or colors.bg

  -- Static highlights for the display window
  vim.api.nvim_set_hl(0, "PiBorder", { fg = colors.blue })
  vim.api.nvim_set_hl(0, "PiTitle", { fg = black, bg = colors.blue, bold = true })

  -- Per-mode highlights for the input window
  local mode_colors = {
    normal = colors.blue,
    insert = colors.green,
    visual = colors.magenta,
    replace = colors.red,
    command = colors.yellow,
  }

  for label, color in pairs(mode_colors) do
    vim.api.nvim_set_hl(0, "PiModeBorder_" .. label, { fg = color })
    vim.api.nvim_set_hl(0, "PiModeTitle_" .. label, { fg = black, bg = color, bold = true })
  end
end

return M
