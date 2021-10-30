call plug#begin(stdpath('data') . '/plugged')
  " A git wrapper.
  Plug 'tpope/vim-fugitive'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'sainnhe/sonokai'
  Plug 'github/copilot.vim'
  " Automatically clear search highlights after you move your cursor.
  Plug 'haya14busa/is.vim'
call plug#end()
