-- This file was copied and adapted from https://github.com/tjdevries/config_manager
--
-- There is no LICENSE associated with the repo, however most, if not all, of author's other OSS repos
-- are licensed under the MIT license.
--
-- I will operate under the assumption that it is intended to be shared, used, and adapted by others
-- as in the README for the repo it is stated that it is okay to use whatever someone likes from it.
-- And that, in the spirit of the author's other OSS repos, it is okay to use the MIT license as a basis
-- for using code from it. If this is incorrect and an issue, please open an issue in my dotfiles repo at
-- https://github.com/joshuadavidthomas/dotfiles and I will work to resolve it.
--
-- There is an open issue on the `config_manager` repo regarding this, but no comments from the author
-- (presumably because it's a dotfiles repo and thus a low priority, plus the aforementioned disclaimer
-- in the README) -- https://github.com/tjdevries/config_manager/issues/27.

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
