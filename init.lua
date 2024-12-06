_G.dd = function(...)
  require("snacks.debug").inspect(...)
end
_G.bt = function()
  require("snacks.debug").backtrace()
end
_G.p = function(...)
  require("snacks.debug").profile(...)
end
vim.print = _G.dd

require("config.lazy")
require("josh").setup()

if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1 then
  -- Neovim was opened with a directory
  vim.print("Opened to directory: " .. vim.fn.argv()[1])
else
  -- Neovim was opened without a directory
  vim.print("Opened without directory")
end
