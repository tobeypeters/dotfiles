" Inspired by Dominik Tarnowski 
" https://medium.com/better-programming/setting-up-neovim-for-web-development-in-2020-d800de3efacd
" Modifications by Tobey Peters [ https://github.com/tobeypeters ]

" Plug-in start
" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin("~/.config/nvim/autoload/plugged")
" Theme
  " Plug 'morhetz/gruvbox'
  " Plug 'joshdick/onedark.vim'
  " Plug 'dracula/vim'
  Plug 'dunstontc/vim-vscode-theme'

  " TypeScript Highlighting
  Plug 'leafgarland/typescript-vim'
  Plug 'peitalin/vim-jsx-typescript'

  " File Explorer with Icons
  Plug 'scrooloose/nerdtree'
  Plug 'ryanoasis/vim-devicons'

  " File Search
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
    
  Plug 'itchyny/lightline.vim'

  Plug 'jeetsukumaran/vim-pythonsense'
call plug#end()

" Automatically install missing plugins on startup
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
" Plug-in stop

" NERDTree start
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeIgnore = []
let g:NERDTreeStatusline = ''
" Automaticaly close nvim if NERDTree is only thing left open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" Toggle
nnoremap <silent> <C-b> :NERDTreeToggle<CR>
" NERDTree stop

" Keymappings start
nnoremap <C-p> :FZF<CR>
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}
" requires silversearcher-ag
" used to ignore gitignore files
let $FZF_DEFAULT_COMMAND = 'ag -g ""'

" turn terminal to normal mode with escape
tnoremap <Esc> <C-\><C-n>

" use alt+hjkl to move between split/vsplit panels
tnoremap <A-h> <C-\><C-n><C-w>h
tnoremap <A-j> <C-\><C-n><C-w>j
tnoremap <A-k> <C-\><C-n><C-w>k
tnoremap <A-l> <C-\><C-n><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
" Keymappings stop

" start terminal in insert mode
au BufEnter * if &buftype == 'terminal' | :startinsert | endif

" open terminal start
function! OpenTerminal()
  split term://bash
  resize 10
endfunction
nnoremap <c-n> :call OpenTerminal()<CR>
" open terminal end

syntax on
syntax enable

" Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
if (empty($TMUX) && has("nvim"))
  "For Neovim 0.1.3 and 0.1.4
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

" Enable theming support
if (has("termguicolors"))
  set termguicolors
endif

set colorcolumn=80
highlight colorcolumn ctermbg=0 guibg=lightgrey

set expandtab
set incsearch
set nu
set nowrap
set noswapfile
set nobackup
set path+=**
set shiftwidth=4
set smartindent
set splitright
set splitbelow
set tabstop=4 softtabstop=4
set undodir=~/.config/nvim/undodir
set undofile
set wildmenu

colorscheme dark_plus

let g:coc_disable_startup_warning = 1
