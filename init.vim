let mapleader = ","

:imap jk <Esc>
:imap kj <Esc>

set nocompatible            " disable compatibility to old-time vi
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
set wildmode=longest,list   " get bash-like tab completions
set cc=72,79,88,119         " set column borders
filetype plugin indent on   " allows auto-indenting depending on file type
syntax on                   " syntax highlighting

runtime ./plug.vim
runtime ./color.vim
