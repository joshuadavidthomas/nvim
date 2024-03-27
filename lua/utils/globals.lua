-- shamelessly stolen from https://github.com/tjdevries/config_manager/blob/eb8c846bdd480e6ed8fb87574eac09d31d39befa/xdg_config/nvim/lua/tj/globals.lua
local require = require

P = function(v)
  print(vim.inspect(v))
  return v
end

RELOAD = function(...)
  local ok, plenary_reload = pcall(require, "plenary.reload")
  local reloader = require
  if ok then
    reloader = plenary_reload.reload_module
  end

  return reloader(...)
end

R = function(name)
  RELOAD(name)
  return require(name)
end

-- function ReloadConfig()
--   local init_lua = vim.fn.stdpath("config") .. "/init.lua"
--   return vim.cmd("source " .. init_lua)
-- end
