local mistyped_commands = {
  W = "w",
  Wa = "wa",
  Wq = "wq",
  Wqa = "wqa",
  Q = "q",
  Qa = "qa",
}

for cmd, base in pairs(mistyped_commands) do
  -- Create regular command
  vim.api.nvim_create_user_command(cmd, function(opts)
    local force = opts.bang and "!" or ""
    vim.cmd(base .. force)
  end, { bang = true })
end

-- Custom commands for wy - write and confirm
-- Uppercase versions (required for user commands)
local save_confirm_commands = {
  "Wy",
  "WY",
}

for _, cmd in ipairs(save_confirm_commands) do
  vim.api.nvim_create_user_command(cmd, function()
    -- Use silent to suppress the prompt
    vim.cmd("silent! w")
  end, {})
end

-- Lowercase version using command abbreviation
vim.cmd("cnoreabbrev wy silent! w")
