local M = {}

M.options = {
  autowrite = true, -- Enable autowrite
  clipboard = { value = vim.env.SSH_TTY and "" or "unnamedplus", schedule = true }, -- Sync with system clipboard, lazily
  completeopt = "menu,menuone,noselect",
  conceallevel = 2, -- Hide * markup for bold and italic, but not markers with substitutions
  confirm = true, -- Confirm to save changes before exiting modified buffer
  cursorline = true, -- enable highlighting of current line
  expandtab = true, -- Use spaces instead of tabs
  fillchars = {
    foldopen = "",
    foldclose = "",
    fold = " ",
    foldsep = " ",
    diff = "╱",
    eob = " ",
  },
  foldlevel = 99,
  grepformat = "%f:%l:%c:%m",
  grepprg = "rg --vimgrep",
  ignorecase = true, -- ingore case
  inccommand = "nosplit", -- preview incremental substitute
  jumpoptions = "view",
  laststatus = 3, -- global statusline
  linebreak = true, -- wrap lines at convenient points,
  list = true, -- show some invisible characters
  listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
    extends = "»",
    precedes = "«",
    eol = "↲",
    space = "·",
  },
  mouse = "a", -- enable mouse mode
  number = true, -- print line number
  pumblend = 10, -- Popup blend
  pumheight = 10, -- Maximum number of entries in a popup
  relativenumber = true, -- relative line numbers
  ruler = false, -- disable the default ruler
  scrolloff = 4, -- lines of context
  sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" },
  shell = "/usr/bin/fish",
  shiftround = true, -- round indent
  shiftwidth = 2, -- size of an indent
  shortmess = { value = { W = true, I = true, c = true, C = true }, append = true },
  showmode = false, -- don't show mode (lualine does this for us)
  sidescrolloff = 8, -- Columns of context
  signcolumn = "yes", -- Always show the signcolumn, otherwise it would shift the text each time
  smartcase = true, -- Don't ignore case with capitals
  smartindent = true, -- insert indents automatically
  smoothscroll = true,
  splitbelow = true, -- Put new windwos below current
  splitkeep = "screen",
  splitright = true, -- Put new windows right of current
  statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]],
  tabstop = 2, -- number of spaces tabs count for
  termguicolors = true, -- True color support
  timeoutlen = vim.g.vscode and 1000 or 300, -- Lower than default (1000) to quickly trigger which-key
  undofile = true,
  undolevels = 10000,
  updatetime = 200, -- save swap file and trigger CursorHold
  wildmode = "longest:full,full", -- command-line completion mode
  wrap = false, -- disable line wrap
}

function M.set_option(name, value)
  vim.opt[name] = value
end

function M.append_option(name, value)
  vim.opt[name]:append(value)
end

function M.setup()
  for name, setting in pairs(M.options) do
    if type(setting) == "table" and setting.value then
      local value = setting.value or setting
      local fn = setting.append and M.append_option or M.set_option
      if setting.schedule then
        vim.schedule(function()
          fn(name, value)
        end)
      else
        fn(name, value)
      end
    else
      M.set_option(name, setting)
    end
  end
end

return M
