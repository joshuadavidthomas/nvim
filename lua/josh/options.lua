local opt = vim.opt
local wo = vim.wo
local g = vim.g

-- Set highlight on search
opt.hlsearch = false

-- Make line numbers default
wo.number = true

-- relativenumbers by default
wo.relativenumber = true

-- Enable mouse mode
opt.mouse = "a"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
opt.clipboard = "unnamedplus"

-- Enable break indent
opt.breakindent = true

-- Save undo history
opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
opt.ignorecase = true
opt.smartcase = true

-- Keep signcolumn on by default
opt.signcolumn = "yes"

-- Decrease update time
opt.updatetime = 250
opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
opt.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
opt.termguicolors = true

-- Enable auto write
opt.autowrite = true

-- Confirm to save changes before exiting modified buffer
opt.confirm = true

-- views can only be fully collapsed with the global statusline
opt.laststatus = 3
-- Default splitting will cause your main splits to jump when opening an edgebar.
-- To prevent this, set `splitkeep` to either `screen` or `topline`.
opt.splitkeep = "screen"

-- python setup
g.python3_host_prog = "/home/josh/.config/nvim/.venv/bin/python"

-- enable list mode to see whitespace
opt.list = true
opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
  extends = "»",
  precedes = "«",
  eol = "↲",
  space = "·",
}
