local commands = {
  W = "w",
  Wa = "wa",
  Wq = "wq",
  Wqa = "wqa",
  Q = "q",
  Qa = "qa",
}

for cmd, base in pairs(commands) do
  -- Create regular command
  vim.api.nvim_create_user_command(cmd, function(opts)
    local force = opts.bang and "!" or ""
    vim.cmd(base .. force)
  end, { bang = true })
end
