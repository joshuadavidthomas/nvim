local M = {}

---@type snacks.win?
local notes_sidebar_win = nil

local config = {
  root_dir = vim.fn.stdpath("data") .. "/notes_sidebar",
  sidebar_position = "right", -- "left" or "right"
  sidebar_width = 60,
  default_note_file = "main_notes.md",
  default_ft = "markdown",
}

local function get_sidebar_win_config()
  ---@type snacks.win.Config
  local win_config = {
    enter = true, -- Focus the window when opening
    focusable = true,
    fixbuf = true, -- Keep this buffer in this window
    position = config.sidebar_position,
    width = config.sidebar_width,
    height = 0, -- Full height for vertical split
    winbar = "%f", -- Show filename
    border = (config.sidebar_position == "right" and "left") or (config.sidebar_position == "left" and "right") or nil,
    relative = "editor",
    wo = {
      wrap = true,
      linebreak = true,
      number = false,
      relativenumber = false,
      signcolumn = "no",
      -- cursorline = true, -- Optional: highlight current line
    },
    -- IMPORTANT: Add an on_close handler to clear our reference
    on_close = function()
      notes_sidebar_win = nil
    end,
  }
  return win_config
end

function M.get_default_note_path()
  vim.fn.mkdir(config.root_dir, "p")
  return config.root_dir .. "/" .. config.default_note_file
end

---@param filepath string The absolute path to the note file to open.
function M.open_note_in_sidebar(filepath)
  filepath = svim.fs.normalize(filepath)

  if notes_sidebar_win and notes_sidebar_win:valid() then
    local current_buf = vim.api.nvim_win_get_buf(notes_sidebar_win.win)
    local target_buf = vim.fn.bufadd(filepath)

    if current_buf ~= target_buf then
      vim.api.nvim_win_set_buf(notes_sidebar_win.win, target_buf)
      vim.bo[target_buf].buflisted = true -- Ensure it shows in buffer list
      vim.bo[target_buf].swapfile = false -- Good idea for notes/scratch
      vim.cmd.doautocmd("BufWinEnter") -- Trigger filetype detection etc.
    end
    if config.win_opts and config.win_opts.enter == true then
      -- Ensure focus if 'enter' is expected behavior
      notes_sidebar_win:focus()
    end

  -- If sidebar doesn't exist, create it with the specified file
  else
    local buf_to_open = vim.fn.bufadd(filepath)
    vim.bo[buf_to_open].buflisted = true
    vim.bo[buf_to_open].swapfile = false
    vim.cmd("silent doautocmd BufAdd " .. filepath) -- Trigger creation events

    local win_config = get_sidebar_win_config()
    win_config.buf = buf_to_open -- Tell snacks.win which buffer to use initially

    notes_sidebar_win = Snacks.win(win_config)
    vim.cmd.doautocmd("BufWinEnter")
  end
end

function M.toggle_notes_sidebar()
  if notes_sidebar_win and notes_sidebar_win:valid() then
    -- Window exists, check if it's the current one
    if vim.api.nvim_get_current_win() == notes_sidebar_win.win then
      -- on_close callback will set notes_sidebar_win to nil
      notes_sidebar_win:close()
    else
      -- It exists but isn't current, focus it
      notes_sidebar_win:focus()
    end
  else
    -- Window doesn't exist (or is invalid), create it with the default file
    M.open_note_in_sidebar(M.get_default_note_path())
  end
end

function M.select_and_open_note()
  vim.fn.mkdir(config.root_dir, "p")

  Snacks.picker({
    source = "files",
    cwd = M.get_notes_root(),
    title = "Select Note",
    layout = { preset = "bottom" },
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        M.open_note_in_sidebar(item.file)
      end
    end,
  })
end

return M
