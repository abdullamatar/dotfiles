set number
set relativenumber

if has('syntax')
  syntax on
endif
set wildmenu
set showcmd
set hlsearch
set ignorecase
set smartcase
set autoindent
set mouse=a
set wrap
set backspace=indent,eol,start
set ttyfast
let mapleader = " "

inoremap jk <Esc>
noremap <leader>w :w<CR>

"6 represents the stable bar in insert mode, while 2 reps the stableblock in anything but insert mode
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

set tabstop =4
set softtabstop=0 noexpandtab
set shiftwidth=4
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
