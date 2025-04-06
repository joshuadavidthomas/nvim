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

-- disable plugin order check
vim.g.lazyvim_check_order = false

require("config.lazy")
require("filetype")
require("utils.globals")
