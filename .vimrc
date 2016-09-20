set nocompatible               " be iMproved
filetype off                   " required!

"""  vundle plugin manager
" git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
" vim +PluginInstall +qall
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" My Bundles here:
" TODO: sort properly
"
Plugin 'L9'
" git
Plugin 'tpope/vim-git.git'
Plugin 'tpope/vim-fugitive.git'
Plugin 'gregsexton/gitv'
"" python
"python-mode is all in one, but hard to make working, try again later
"Bundle 'https://github.com/klen/python-mode.git'
Plugin 'https://github.com/scrooloose/syntastic.git'
Plugin 'https://github.com/python-rope/ropevim.git'
Plugin 'fs111/pydoc.vim.git'
Plugin 'michaeljsmith/vim-indent-object'
" Getting pep8 through syntastic
"Bundle 'vim-scripts/pep8.git'
Plugin 'alfredodeza/pytest.vim.git'
Plugin 'jmcantrell/vim-virtualenv'
" Plugin 'vim-flake8'
Plugin 'andviro/flake8-vim'
"" jedi is not compatible with youcompleteme
Plugin 'https://github.com/davidhalter/jedi-vim.git'
"" code helpers
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/nerdcommenter'
Plugin 'https://github.com/nathanaelkane/vim-indent-guides.git'
Plugin 'tpope/vim-surround.git'
Plugin 'tpope/vim-repeat.git'
Plugin 'vim-scripts/TaskList.vim'
"" Misc scripts
Plugin 'https://github.com/ctrlpvim/ctrlp.vim.git'
Bundle 'amiorin/ctrlp-z'
Plugin 'https://github.com/scrooloose/nerdtree.git'
Plugin 'sjl/gundo.vim.git'
Plugin 'chrisbra/changesPlugin'
Plugin 'https://github.com/Lokaltog/vim-easymotion.git'
" Plugin 'Raimondi/delimitMate'
Plugin 'jiangmiao/auto-pairs'
Plugin 'tmux-plugins/vim-tmux-focus-events'
" replacing ultisnips with neosnips for now
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'https://github.com/Valloric/YouCompleteMe.git'
"Bundle 'ervandew/supertab.git'
"Bundle 'Shougo/neosnippet.git'
"Bundle 'Shougo/neocomplcache'
"" color schemes and appearance
"Plugin 'Lokaltog/vim-powerline'
Plugin 'Solarized'
Plugin 'jnurmine/Zenburn'
Plugin 'https://github.com/nanotech/jellybeans.vim'
Plugin 'https://github.com/sickill/vim-monokai.git'
Plugin 'https://github.com/tomasr/molokai.git'
Plugin 'https://github.com/notpratheek/Pychimp-vim.git'
Plugin 'https://github.com/ambidexterich/mustang.git'
Plugin 'https://github.com/akmassey/vim-codeschool.git'
Plugin 'https://github.com/tpope/vim-vividchalk.git'
Plugin 'https://github.com/jonathanfilip/vim-lucius.git'
call vundle#end()

" Load vim-plug
if empty(glob("~/.vim/autoload/plug.vim"))
    " Ensure all needed directories exist  (Thanks @kapadiamush)
    execute 'mkdir -p ~/.vim/plugged'
    execute 'mkdir -p ~/.vim/autoload'
    " Download the actual plugin manager
    execute '!curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install'  }
Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

filetype plugin indent on                   " required!
call plug#end()

""""""""""" REST OF CONFIG

" ==========================================================
" Shortcuts
" ==========================================================
let mapleader=","             " change the leader to be a comma vs backslash

" Seriously, guys. It's not like :W is bound to anything anyway.
command! W :w
command! Q :q

" sudo write this
cmap W! w !sudo tee % >/dev/null
" for when we forget to use sudo to open/edit a file
cmap w!! w !sudo tee % >/dev/null

" ctrl-jklm  changes to that split
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" and lets make these all work in insert mode too ( <C-O> makes next cmd
"  happen as if in command mode )
imap <C-W> <C-O><C-W>

" ======= PLUGINS shortcuts
"

""" easymotion plugin
" reset from leader leader to single leader
map <Leader> <Plug>(easymotion-prefix)
" <Leader>f{char} to move to {char}
map  <Leader>f <Plug>(easymotion-bd-f)
nmap <Leader>f <Plug>(easymotion-overwin-f)
" s{char}{char} to move to {char}{char}
nmap s <Plug>(easymotion-overwin-f2)
" Move to line
map <Leader>L <Plug>(easymotion-bd-jk)
nmap <Leader>L <Plug>(easymotion-overwin-line)
" Move to word
map  <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>w <Plug>(easymotion-overwin-w)
" search overridden by easymotion
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

" ctrlp
let g:ctrlp_max_files=0

" ctrlp-z
let g:ctrlp_z_nerdtree = 1
nnoremap sz :CtrlPZ<Cr>
nnoremap sf :CtrlPF<Cr>

" Toggle the tasklist
map <leader>td <Plug>TaskList

" Run pep8
let g:pep8_map='<leader>F6'

" run py.test's
nmap <silent><Leader>tf <Esc>:Pytest file<CR>
nmap <silent><Leader>tc <Esc>:Pytest class<CR>
nmap <silent><Leader>tm <Esc>:Pytest method<CR>
nmap <silent><Leader>tn <Esc>:Pytest next<CR>
nmap <silent><Leader>tp <Esc>:Pytest previous<CR>
nmap <silent><Leader>te <Esc>:Pytest error<CR>


" Open NerdTree
map <leader>n :NERDTreeToggle<CR>

" Load the Gundo window
map <leader>u :GundoToggle<CR>

""" rope-vim
" Jump to the definition of whatever the cursor is on
map <leader>j :RopeGotoDefinition<CR>
" Rename whatever the cursor is on (including references to it)
map <leader>r :RopeRename<CR>

" Tagbar
map <leader>t :TagbarToggle<CR>

" changesPlugin:
let g:changes_vcs_check=1 " automatically detect VCS-system
" let g:changes_vcs_system='git'

" ==========================================================
" Basic Settings
" ==========================================================
syntax on                     " syntax highlighing
filetype on                   " try to detect filetypes
filetype plugin indent on     " enable loading indent file for filetype
"set number                    " Display line numbers
set relativenumber            " Display line numbers relative to current line
set numberwidth=1             " using only 1 column (and 1 space) while possible
set background=dark           " We are using dark background in vim
set title                     " show title in console title bar
set wildmenu                  " Menu completion in command mode on <Tab>
set wildmode=longest,list,full             " <Tab> cycles between all matching choices.

" don't bell or blink
set noerrorbells
set vb t_vb=

" Ignore these files when completing
set wildignore+=*.o,*.obj,.git,*.pyc
set grepprg=ack-grep          " replace the default grep program with ack

" Set working directory
nnoremap <leader>. :lcd %:p:h<CR>

" Disable the colorcolumn when switching modes.  Make sure this is the
" first autocmd for the filetype here
autocmd FileType * setlocal colorcolumn=0

" show a line at column 79
if exists("&colorcolumn")
    set colorcolumn=79
endif

""" Moving Around/Editing
set cursorline              " have a line indicate the cursor location
set ruler                   " show the cursor position all the time
set nostartofline           " Avoid moving cursor to BOL when jumping around
set virtualedit=block       " Let cursor move past the last char in <C-v> mode
set scrolloff=3             " Keep 3 context lines above and below the cursor
set backspace=indent,eol,start  " Allow backspacing over autoindent, EOL, and BOL
set showmatch               " Briefly jump to a paren once it's balanced
set nowrap                  " don't wrap text
set linebreak               " don't wrap textin the middle of a word
set autoindent              " always set autoindenting on
" smartindent is old and useless according to the internet
"set smartindent             " use smart indent if there is no indent file
set tabstop=4               " <tab> inserts 4 spaces
set shiftwidth=4            " but an indent level is 2 spaces wide.
set softtabstop=4           " <BS> over an autoindent deletes both spaces.
set expandtab               " Use spaces, not tabs, for autoindent/tab key.
set shiftround              " rounds indent to a multiple of shiftwidth
set matchpairs+=<:>         " show matching <> (html mainly) as well
set foldmethod=indent       " allow us to fold on indents
set foldlevel=99            " don't fold by default

" don't outdent hashes
" inoremap # #

" close preview window automatically when we move around
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif

"""" Reading/Writing
set noautowrite             " Never write a file unless I request it.
set noautowriteall          " NEVER.
set noautoread              " Don't automatically re-read changed files.
set modeline                " Allow vim options to be embedded in files;
set modelines=5             " they must be within the first or last 5 lines.
set ffs=unix,dos,mac        " Try recognizing dos, unix, and mac line endings.

"""" Messages, Info, Status
set ls=2                    " allways show status line
set vb t_vb=                " Disable all bells.  I hate ringing/flashing.
set confirm                 " Y-N-C prompt if closing with unsaved changes.
set showcmd                 " Show incomplete normal mode commands as I type.
set report=0                " : commands always print changed line count.
set shortmess+=a            " Use [+]/[RO]/[w] for modified/readonly/written.
set ruler                   " Show some info, even without statuslines.
set laststatus=2            " Always show statusline, even if only 1 window.
set statusline=[%l,%v\ %P%M]\ %f\ %r%h%w\ (%{&ff})\ %{fugitive#statusline()}

" displays tabs with :set list & displays when a line runs off-screen
" set listchars=tab:>-,eol:$,trail:-,precedes:<,extends:>
set list
set listchars=tab:▸\ ,trail:·,precedes:<,extends:>

" Highlight whitespace at end of line
"highlight ExtraWhitespace ctermbg=red guibg=red
"match ExtraWhitespace /\s\+$/
"autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
"autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
"autocmd InsertLeave * match ExtraWhitespace /\s\+$/
"autocmd BufWinLeave * call clearmatches()

autocmd InsertEnter * syn clear EOLWS | syn match EOLWS excludenl /\s\+\%#\@!$/
autocmd InsertLeave * syn clear EOLWS | syn match EOLWS excludenl /\s\+$/
highlight EOLWS ctermbg=red guibg=red

" Highlight non-ascii characters
au BufReadPost * syntax match nonascii "[^\u0000-\u007F]"
highlight nonascii guibg=Red ctermbg=1 term=standout

""" Searching and Patterns
set ignorecase              " Default to using case insensitive searches,
set smartcase               " unless uppercase letters are used in the regex.
set smarttab                " Handle tabs more intelligently
set hlsearch                " Highlight searches by default.
set incsearch               " Incrementally search while typing a /regex
set gdefault                " Search and replace globally by default.
nmap <silent> ,/ :nohlsearch<CR> " Clear searches by typing ,/"
" use normal regular expressions (annoying))
" nnoremap / /\v
" vnoremap / /\v


"""" Display
"set t_Co=256
if has("gui_running") || &t_Co == 256
    colorscheme solarized
    "colorscheme xoria256
    "colorscheme zenburn
    "colorscheme desert256
else
    colorscheme xoria256
    "colorscheme torte
    "colorscheme desert256
    "colorscheme zenburn
endif


" vim powerline, fancy prompt
"let g:powerline_pycmd = "py3"
"let g:Powerline_symbols = 'fancy'

" Enable vim-airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif



set encoding=utf-8

" Paste from clipboard
map <leader>p "+gP

" Quit window on <leader>q
nnoremap <leader>q :q<CR>
"
" hide matches on <leader>space
nnoremap <leader><space> :nohlsearch<cr>

" Remove trailing whitespace on <leader>S
nnoremap <leader>S :%s/\s\+$//<cr>:let @/=''<CR>

" Select the item in the list with enter
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" ===========================================================
" FileType specific changes
" ============================================================
" Mako/HTML
autocmd BufNewFile,BufRead *.mako,*.mak setlocal ft=html
autocmd FileType html,xhtml,xml,css setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2

" ==========================================================
" Python
" ==========================================================
"au BufRead *.py compiler nose
au FileType python set omnifunc=pythoncomplete#Complete
au FileType python setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4
au BufRead *.py set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m

" jedi-vim {
let g:jedi#auto_vim_configuration = 0
let g:jedi#popup_on_dot = 0
let g:jedi#popup_select_first = 0
let g:jedi#completions_enabled = 0
let g:jedi#completions_command = ""
let g:jedi#show_call_signatures = "1"

let g:jedi#goto_assignments_command = "<leader>pa"
let g:jedi#goto_definitions_command = "<leader>pd"
let g:jedi#documentation_command = "<leader>pk"
let g:jedi#usages_command = "<leader>pu"
let g:jedi#rename_command = "<leader>pr"
" }

" flake8-vim ignore lang lines error:
let g:flake8_ignore="E501"
" run flake8 when saving file
"autocmd BufWritePost *.py call Flake8()

" Don't let pyflakes use the quickfix window
"let g:syntastic_python_checkers=['pylint', 'flake8']
let g:syntastic_check_on_open=0
let g:syntastic_enable_signs=1
" Better :sign interface symbols
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '!'
let g:syntastic_python_checkers=['flake8']
let g:syntastic_mode_map = { 'mode': 'active',
    \ 'active_filetypes': ['python', 'php'],
    \ 'passive_filetypes': ['puppet'] }
let g:syntastic_python_flake8_args='--ignore=E501'

"" YouComleteMe
let g:ycm_autoclose_preview_window_after_completion=1
nnoremap <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>
" disable tab in ycm as to not interefer with ultisnips, use c-n/c-p
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]

let g:AutoPairsFlyMode = 1

" Multiline comment:
if 0
i

this is a multiline comment hack
vim, since it only supports single line
comments

.
endif
" Multiline comment ends

