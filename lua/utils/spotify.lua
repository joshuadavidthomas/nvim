local icons = require("utils.icons")

local M = {}

M.current_track = ""

local CLI = "spotify_dbus"
local update_interval_sec = 5
local update_timer = nil
local pause_timeout_sec = 60
local pause_timer = nil
local last_call = nil
local last_known_status = nil

local function refresh_lualine()
  if package.loaded.lualine then
    vim.schedule(function()
      pcall(require("lualine").refresh)
    end)
  end
end

local function format_track_string(data)
  if not data then
    return icons.misc.music .. "Not available"
  end

  local playback_icon = icons.misc.music
  if data.playback_status == "Playing" then
    playback_icon = icons.misc.play
  elseif data.playback_status == "Paused" then
    playback_icon = icons.misc.pause
  end

  local metadata = data.metadata
  if not metadata then
    return playback_icon .. "No metadata"
  end

  local title = metadata["xesam:title"] or "Unknown Title"
  local artists = metadata["xesam:artist"]
  local artist_string = "Unknown Artist"
  if artists and type(artists) == "table" and #artists > 0 then
    artist_string = table.concat(artists, ", ")
  end

  return string.format("%s %s - %s", playback_icon, artist_string, title)
end

local function clear_pause_timer()
  if pause_timer and not pause_timer:is_closing() then
    pause_timer:close()
  end
  pause_timer = nil
end

local function on_pause_timeout()
  if last_known_status == "Paused" and M.current_track ~= "" then
    M.current_track = ""
    refresh_lualine()
  end
  pause_timer = nil
end

local function process_and_update_cache(json_to_decode)
  local ok, decoded_data = pcall(vim.fn.json_decode, json_to_decode)
  local new_track_string = ""
  local current_status = nil

  if ok and decoded_data then
    if decoded_data.success and decoded_data.data then
      current_status = decoded_data.data.playback_status

      if current_status == "Playing" then
        new_track_string = format_track_string(decoded_data.data)
        clear_pause_timer() -- Playing, so stop any pause timeout
      elseif current_status == "Paused" then
        -- Show Paused only if the previous state was also Playing or Paused
        if last_known_status == "Playing" or last_known_status == "Paused" then
          new_track_string = format_track_string(decoded_data.data)
          -- Start pause timer only if showing the paused state
          if not pause_timer or pause_timer:is_closing() then
            pause_timer = vim.uv.new_timer()
            if pause_timer then
              pause_timer:start(pause_timeout_sec * 1000, 0, vim.schedule_wrap(on_pause_timeout))
            else
              vim.notify("Spotify: Failed to create pause timer.", vim.log.levels.ERROR)
            end
          end
        else
          -- Previous state was nil, Stopped, Error, etc. Keep display empty.
          new_track_string = ""
          clear_pause_timer() -- Ensure no timer running if not displaying
        end
      else
        -- Status is Stopped or something else unexpected
        new_track_string = "" -- Show nothing
        clear_pause_timer()
      end
    else
      -- JSON structure error
      local reason = decoded_data.success == false and "success:false" or "data missing"
      vim.notify("Spotify JSON Content Error: " .. reason, vim.log.levels.WARN)
      local error_icon = icons.misc.error or "!"
      new_track_string = error_icon .. " Content Error" -- Show error
      current_status = "Error" -- Set status to Error
      clear_pause_timer()
    end
  else
    -- JSON decoding error
    vim.notify("Spotify JSON Decode Error: " .. tostring(decoded_data), vim.log.levels.ERROR)
    local error_icon = icons.misc.error or "!"
    new_track_string = error_icon .. " Decode Error" -- Show error
    current_status = "Error" -- Set status to Error
    clear_pause_timer()
  end

  -- Update the public variable only if the calculated string changed
  if new_track_string ~= M.current_track then
    M.current_track = new_track_string
    refresh_lualine()
  end

  -- IMPORTANT: Update last_known_status *after* processing
  last_known_status = current_status
end

local function update_track_info_async()
  local cmd_parts = { CLI, "--json", "status" }

  vim.system(cmd_parts, { text = true }, function(obj)
    if obj.code == 0 then
      local current_stdout = obj.stdout
      if current_stdout and #current_stdout > 0 and current_stdout ~= last_call then
        last_call = current_stdout
        vim.schedule(function()
          process_and_update_cache(last_call)
        end)
      elseif not current_stdout or #current_stdout == 0 then
        -- Empty output means stopped/idle. We need to trigger an update
        -- so process_and_update_cache can set the display to "" and update last_known_status.
        -- We can simulate a "Stopped" status JSON, or just directly update state here.
        -- Let's directly update state for simplicity if output is empty.
        if M.current_track ~= "" then
          M.current_track = ""
          refresh_lualine()
        end
        if last_known_status ~= "Stopped" then
          last_known_status = "Stopped"
        end
        clear_pause_timer()
        last_call = current_stdout
      end
    else
      local failure_message = ""
      if M.current_track ~= failure_message then
        M.current_track = failure_message
        refresh_lualine()
      end
      last_call = nil
      if last_known_status ~= "Not Running" then
        last_known_status = "Not Running"
      end
      clear_pause_timer()
    end
  end)
end

local stop_updater = function()
  if update_timer and not update_timer:is_closing() then
    update_timer:close()
  end
  update_timer = nil

  clear_pause_timer()
end

local function start_updater()
  stop_updater()

  update_timer = vim.uv.new_timer()
  if not update_timer then
    vim.notify("Spotify: Failed to create update timer.", vim.log.levels.ERROR)
    return
  end

  update_timer:start(
    0,
    update_interval_sec * 1000,
    vim.schedule_wrap(function()
      pcall(update_track_info_async)
    end)
  )
end

start_updater()

vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    stop_updater()
  end,
  desc = "Stop Spotify updater timers on exit",
})

return M
