local icons = require("utils.icons")

local M = {}

M.config = {
  pause_timeout_sec = 30,
  icons = {
    playing = icons.misc.music,
    paused = icons.misc.pause,
  },
}

function M.get_config()
  return M.config
end

M.current_track = ""

function M.format_track(status, track_info)
  if not track_info then
    return ""
  end

  if status == "Playing" then
    return M.config.icons.playing .. " " .. track_info
  elseif status == "Paused" then
    return M.config.icons.paused .. " " .. track_info
  end

  return ""
end

function M.update_track(track_text)
  vim.notify(track_text)
  if M.current_track ~= track_text then
    M.current_track = track_text

    if package.loaded.lualine then
      vim.schedule(function()
        pcall(require("lualine").refresh)
      end)
    end
  end
end

function M.setup(opts)
  opts = opts or {}

  M.config = vim.tbl_deep_extend("force", M.config, opts)
end

return M
