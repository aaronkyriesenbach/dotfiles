" Install vim-plug if not found
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

Plug 'dracula/vim', {'as': 'dracula'}
Plug 'chrisbra/Colorizer'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" Enable Dracula colorscheme
colorscheme dracula

" Enable syntax highlighting
syntax enable

" Show line numbers
set number

" Show highlight on current line
set cursorline

" Show matching parentheses/equivalent
set showmatch

" Enable dynamic searching
set incsearch

" Map b to beginning of line and e to end of line, remove default BOL/EOL bindings
nnoremap b ^
nnoremap e $
nnoremap ^ <nop>
nnoremap $ <nop>

" Tab/indentation config
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smartindent

" Enable automatic colorizing
:let g:colorizer_auto_color = 1
