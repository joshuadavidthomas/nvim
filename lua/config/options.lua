local opt = vim.opt
local g = vim.g

opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
  extends = "»",
  precedes = "«",
  eol = "↲",
  space = "·",
}

-- python setup
g.python3_host_prog = "/home/josh/.config/nvim/.venv/bin/python"
g.lazyvim_python_lsp = "basedpyright"

-- disable snacks.animate
g.snacks_animate = false

-- use snacks.picker
g.lazyvim_picker = "snacks"
