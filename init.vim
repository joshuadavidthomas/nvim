let mapleader = ","

:imap jk <Esc>
:imap kj <Esc>

set showmatch               " show matching brackets.
set ignorecase              " case insensitive matching
set mouse=v                 " middle-click paste with mouse
set hlsearch                " highlight search results
set tabstop=4               " number of columns occupied by a tab character
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set expandtab               " converts tabs to white space
set shiftwidth=4            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
set number                  " add line numbers
set relativenumber          " Enable relative line numbers
set wildmode=longest,list   " get bash-like tab completions
set cc=72,79,88,119         " set column borders
filetype plugin indent on   " allows auto-indenting depending on file type

" Section: Plugins

call plug#begin(stdpath('data') . '/plugged')

" sensible defaults
Plug 'tpope/vim-sensible'

" line comments
" `gcc` comments out a line (takes a count)
" `gc` comments a motion (e.g. `gcap` comments out a paragraph)
Plug 'tpope/vim-commentary'

" surround.vim: Delete/change/add parentheses/quotes/XML-tags/much more with ease
Plug 'tpope/vim-surround'

" repeat.vim: enable repeating supported plugin maps with .
Plug 'tpope/vim-repeat'

" git management within vim/neovim
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

" line gutter symbols for git
Plug 'airblade/vim-gitgutter'
set updatetime=100

" fuzzy search
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" editorconfig support
Plug 'editorconfig/editorconfig-vim'

" code completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" treesitter syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" sonokai theme
Plug 'sainnhe/sonokai'
Plug 'itchyny/lightline.vim'
Plug 'github/copilot.vim'

" Automatically clear search highlights after you move your cursor.
Plug 'haya14busa/is.vim'

call plug#end()

" Section: Colors/Theming

syntax on                   " syntax highlighting

" Enable 24-bit true colors if your terminal supports it.
if (has("termguicolors"))
  " https://github.com/vim/vim/issues/993#issuecomment-255651605
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

  set termguicolors
endif

" The configuration options should be placed before `colorscheme sonokai`.
let g:sonokai_style = 'atlantis'
let g:sonokai_enable_italic = 1
let g:sonokai_disable_italic_comment = 1

colorscheme sonokai
set background=dark
