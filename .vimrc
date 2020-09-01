call plug#begin()

Plug 'lifepillar/vim-solarized8'
Plug 'dylanaraps/wal.vim'
Plug 'mbbill/undotree'
Plug 'chrisbra/Colorizer'

call plug#end()

" Enable solarized dark colorscheme
colorscheme wal " solarized8

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

" 4 space tabs
set tabstop=4

" Map UndoTree toggle
nnoremap <F5> :UndotreeToggle<CR>

" Enable automatic colorizing
:let g:colorizer_auto_color = 1
