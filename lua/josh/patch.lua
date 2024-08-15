-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/617
require("nvim-treesitter.compat").flatten = function(t) ---@diagnostic disable-line: duplicate-set-field
  return vim.tbl_flatten(t) ---@diagnostic disable-line: deprecated
end
