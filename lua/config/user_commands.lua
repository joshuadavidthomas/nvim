vim.api.nvim_create_user_command("ReloadConfig", function()
  local config_path = vim.fn.stdpath("config")
  vim.cmd("source " .. config_path .. "/init.lua")
end, { nargs = 0 })
