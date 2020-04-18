call plug#begin()

Plug 'lifepillar/vim-solarized8'
Plug 'mbbill/undotree'

call plug#end()

" Enable solarized dark colorscheme
colorscheme solarized8

" Enable syntax highlighting
syntax enable

" Set 4 visual spaces per TAB
set tabstop=4

" Set 4 actual spaces per TAB
set softtabstop=4

" Show line numbers
set number

" Show highlight on current line
set cursorline

" Show matching parentheses/equivalent
set showmatch

" Enable dynamic searching
set incsearch

" Highlight search matches and bind space to :nohlsearch (stop highlighting)
set hlsearch
nnoremap <leader><space> :nohlsearch<CR>

" Map b to beginning of line and e to end of line, remove default BOL/EOL bindings
nnoremap b ^
nnoremap e $
nnoremap ^ <nop>
nnoremap $ <nop>

" Map UndoTree toggle
nnoremap <F5> :UndotreeToggle<CR>
