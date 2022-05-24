source plugins.vim

colorscheme dracula

set number " Line numbers
set cursorline " Highlight current line
set showmatch " Show matching brackets
set incsearch " Dynamic searching
set clipboard=unnamedplus

" Tab/indent config
set tabstop=8
set expandtab
set shiftwidth=4
set autoindent
set smartindent
set cindent

" Use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()

source textwidth.vim
source tex.vim
source templates.vim
