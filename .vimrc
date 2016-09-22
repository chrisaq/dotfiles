set nocompatible               " be iMproved
" filetype off                   " required!

" Load vim-plug
if empty(glob("~/.vim/autoload/plug.vim"))
    " Ensure all needed directories exist  (Thanks @kapadiamush)
    " execute 'mkdir -p ~/.vim/plugged'
    " execute 'mkdir -p ~/.vim/autoload'
    silent !mkdir -p ~/.vim/plugged > /dev/null 2>&1
    silent !mkdir -p ~/.vim/autoload > /dev/null 2>&1
    " Download the actual plugin manager
    execute '!curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/plugged')
let g:plug_url_format = 'git@github.com:%s.git'
let g:plug_timeout = 600

" My Bundles here:
" TODO: sort properly
"
"" libraries
Plug 'vim-scripts/L9'
" git
Plug 'tpope/vim-git'
Plug 'tpope/vim-fugitive'
Plug 'gregsexton/gitv'
"" python
Plug 'scrooloose/syntastic'
" rope doesn't workj with py3 yet
" Plug 'python-rope/ropevim'
Plug 'fs111/pydoc.vim'
Plug 'michaeljsmith/vim-indent-object'
" Getting pep8 through syntastic
Plug 'alfredodeza/pytest.vim'
Plug 'jmcantrell/vim-virtualenv'
" Plugin 'vim-flake8'
" flake8-vim conflict with youcompleteme:
" https://github.com/Valloric/YouCompleteMe/issues/2262
"Plug 'andviro/flake8-vim'
Plug 'davidhalter/jedi-vim'
"" code helpers
Plug 'majutsushi/tagbar'
Plug 'scrooloose/nerdcommenter'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'vim-scripts/TaskList.vim'
Plug 'ap/vim-css-color'
"" Misc scripts
"Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install'  }
Plug 'junegunn/fzf', { 'dir': $XDG_DATA_HOME . '/fzf', 'do': 'yes n \| ./install' }
Plug 'junegunn/fzf.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'amiorin/ctrlp-z'
Plug 'scrooloose/nerdtree'
Plug 'sjl/gundo.vim'
Plug 'chrisbra/changesPlugin'
Plug 'Lokaltog/vim-easymotion'
" Plug 'Raimondi/delimitMate'
Plug 'jiangmiao/auto-pairs'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'Valloric/YouCompleteMe'
"" color schemes and appearance
Plug 'vim-scripts/Solarized'
Plug 'jnurmine/Zenburn'
Plug 'nanotech/jellybeans.vim'
Plug 'sickill/vim-monokai'
Plug 'tomasr/molokai'
Plug 'notpratheek/Pychimp-vim'
Plug 'ambidexterich/mustang'
" Plug 'akmassey/vim-codeschoolgit' " Gone
" Plug 'tpope/vim-vividchalkgit' " Gone
Plug 'jonathanfilip/vim-lucius'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

filetype plugin indent on                   " required!
call plug#end()

""""""""""" REST OF CONFIG

" ==========================================================
" Shortcuts
" ==========================================================
"let mapleader=","             " change the leader to be a comma vs backslash
let mapleader="\<Space>"             " Testing space...

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

" Paste from clipboard
map <leader>p "+gP

" Quit window on <leader>q
nnoremap <leader>q :q<CR>
"
" hide matches on <leader>space
nnoremap <leader><space> :nohlsearch<cr>

" Remove trailing whitespace on <leader>S
nnoremap <leader>S :%s/\s\+$//<cr>:let @/=''<CR>


" ==========================================================
" PLUGINS shortcuts
" ==========================================================


""" easymotion plugin
" reset from leader leader to single leader
" allows single leader commands below
" map <Leader> <Plug>(easymotion-prefix)
"
"" <Leader>f{char} to move to {char}
"map  <Leader>f <Plug>(easymotion-bd-f)
"nmap <Leader>f <Plug>(easymotion-overwin-f)
"" s{char}{char} to move to {char}{char}
"nmap s <Plug>(easymotion-overwin-f2)
"" Move to line
"map <Leader>L <Plug>(easymotion-bd-jk)
"nmap <Leader>L <Plug>(easymotion-overwin-line)
"" Move to word
"map  <Leader>w <Plug>(easymotion-bd-w)
"nmap <Leader>w <Plug>(easymotion-overwin-w)
" search overridden by easymotion
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

""" fzf
"imap <C-f> <plug>(fzf-complete-line)
nnoremap <c-f> :FZF<cr>
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
"nnoremap <silent> <leader><space> :Files<CR>
nnoremap <silent> <leader>ff :Files<CR>
"nnoremap <silent> <leader>a :Buffers<CR>
nnoremap <silent> <leader>fb :Buffers<CR>
"nnoremap <silent> <leader>A :Windows<CR>
nnoremap <silent> <leader>fw :Windows<CR>
"nnoremap <silent> <leader>; :BLines<CR>
nnoremap <silent> <leader>fl :BLines<CR>
"nnoremap <silent> <leader>o :BTags<CR>
nnoremap <silent> <leader>ft :BTags<CR>
"nnoremap <silent> <leader>O :Tags<CR>
nnoremap <silent> <leader>fT :Tags<CR>
"nnoremap <silent> <leader>? :History<CR>
nnoremap <silent> <leader>? :History<CR>
nnoremap <silent> <leader>/ :execute 'Ag ' . input('Ag/')<CR>
nnoremap <silent> <leader>. :AgIn
nnoremap <silent> K :call SearchWordWithAg()<CR>
vnoremap <silent> K :call SearchVisualSelectionWithAg()<CR>
nnoremap <silent> <leader>gl :Commits<CR>
nnoremap <silent> <leader>ga :BCommits<CR>
nnoremap <silent> <leader>ft :Filetypes<CR>
imap <C-x><C-f> <plug>(fzf-complete-file-ag)
imap <C-x><C-l> <plug>(fzf-complete-line)

" ctrlp-z
let g:ctrlp_z_nerdtree = 1
nnoremap sz :CtrlPZ<Cr>
nnoremap sf :CtrlPF<Cr>

" Toggle the tasklist
map <leader>td <Plug>TaskList

""" vim-fugitive
nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gd :Gdiff<CR>
nnoremap <silent> <leader>gc :Gcommit<CR>
nnoremap <silent> <leader>gb :Gblame<CR>
nnoremap <silent> <leader>ge :Gedit<CR>
nnoremap <silent> <leader>gE :Gedit<space>
nnoremap <silent> <leader>gr :Gread<CR>
nnoremap <silent> <leader>gR :Gread<space>
nnoremap <silent> <leader>gw :Gwrite<CR>
nnoremap <silent> <leader>gW :Gwrite!<CR>
nnoremap <silent> <leader>gq :Gwq<CR>
nnoremap <silent> <leader>gQ :Gwq!<CR>


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
let g:NERDTreeMapOpenSplit='x'
let g:NERDTreeMapOpenVSplit='v'

" Load the Gundo window
map <leader>u :GundoToggle<CR>

""" rope-vim - disabled until py3 support is in place
" Jump to the definition of whatever the cursor is on
"map <leader>j :RopeGotoDefinition<CR>
" Rename whatever the cursor is on (including references to it)
"map <leader>r :RopeRename<CR>

" Tagbar
map <leader>t :TagbarToggle<CR>


" ==========================================================
" Basic Settings
" ==========================================================
syntax on                     " syntax highlighing
filetype on                   " try to detect filetypes
filetype plugin indent on     " enable loading indent file for filetype
set number                    " Display current line number
set relativenumber            " Display line numbers relative to current line
set numberwidth=1             " using only 1 column (and 1 spa4e) while possible
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
set shiftwidth=4            " but an indent level is 4 spaces wide.
set softtabstop=4           " <BS> over an autoindent deletes 4 spaces.
set expandtab               " Use spaces, not tabs, for autoindent/tab key.
set shiftround              " rounds indent to a multiple of shiftwidth
set matchpairs+=<:>         " show matching <> (html mainly) as well
set foldmethod=indent       " allow us to fold on indents
set foldlevel=99            " don't fold by default

" don't outdent hashes
" inoremap # #

""" Preview window
" close preview window automatically when we move around
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif
" Select the item in the list with enter
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use the Up/Down arrow and PgUp/PgDn keys to scroll through the popup menu.
" The word in text will change as you scroll through. Press Enter to accept
" the selected word. Hit Esc to cancel completion and go back to the original
" word.
"inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
"inoremap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"
"inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
"inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
"inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
"inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"

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

set encoding=utf-8


" ===========================================================
" FileType specific configuration
" ============================================================

""" Open new/empty files in insert mode - NOTE: opens gundo in insert mode :(
" au BufNewFile * startinsert
""" Open new/empty buffers in insert mode
" autocmd VimEnter * if empty(expand("%")) | startinsert | endif

""" Mako/HTML
autocmd BufNewFile,BufRead *.mako,*.mak setlocal ft=html
autocmd FileType html,xhtml,xml,css setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2

""" Python
au FileType python set omnifunc=pythoncomplete#Complete
au FileType python setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4
au BufRead *.py set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m


" =====================================================
"                   ------- --------
" #########         Plugins settings      #############
"                   ------- --------
" =====================================================

" ==========================
" Edit/basic plugin settings
" ==========================

""" AutoPairs
let g:AutoPairsFlyMode = 0

""" changesPlugin
" let g:changes_vcs_check=1 " automatically detect VCS-system
let g:changes_vcs_system='git'

""" ctrlp
let g:ctrlp_max_files=0

""" fzf
function! SearchWordWithAg()
    execute 'Ag' expand('<cword>')
endfunction

function! SearchVisualSelectionWithAg() range
    let old_reg = getreg('"')
    let old_regtype = getregtype('"')
    let old_clipboard = &clipboard
    set clipboard&
    normal! ""gvy
    let selection = getreg('"')
    call setreg('"', old_reg, old_regtype)
    let &clipboard = old_clipboard
    execute 'Ag' selection
endfunction

function! SearchWithAgInDirectory(...)
    call fzf#vim#ag(join(a:000[1:], ' '), extend({'dir': a:1}, g:fzf#vim#default_layout))
endfunction

command! -nargs=+ -complete=dir AgIn call SearchWithAgInDirectory(<f-args>)


" ===========================
" Programming plugin settings
" ===========================

""" Syntastic
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

""" YouComleteMe
let g:ycm_server_python_interpreter = '/usr/bin/python3'
" let g:ycm_python_binary_path = '/usr/bin/python3'
let g:ycm_autoclose_preview_window_after_completion=1
nnoremap <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>
" disable tab in ycm as to not interefer with ultisnips, use c-n/c-p
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]
" let g:ycm_path_to_python_interpreter="/usr/bin/python2"
" ycm debug
let g:ycm_server_keep_logfiles = 1
let g:ycm_server_log_level = 'debug'


" =====================
" Python settings
" =====================

""" jedi-vim {
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#popup_on_dot = 0
let g:jedi#popup_select_first = 0
let g:jedi#completions_enabled = 0
let g:jedi#completions_command = ""
let g:jedi#show_call_signatures = "1"
" according to somewhere the below needed to handle ycm issue
let g:jedi#show_call_signatures_delay = 0

let g:jedi#goto_assignments_command = "<leader>pa"
let g:jedi#goto_definitions_command = "<leader>pd"
let g:jedi#documentation_command = "<leader>pk"
let g:jedi#usages_command = "<leader>pu"
let g:jedi#rename_command = "<leader>pr"
" }

""" flake8-vim
" flake8-vim ignore lang lines error:
let g:flake8_ignore="E501"
" run flake8 when saving file
"autocmd BufWritePost *.py call Flake8()


" =====================
" Color/theme settings
" =====================

"""" Colors / themes
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

""" vim-airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_theme='solarized'

" Multiline comment:
if 0
i

this is a multiline comment hack
vim, since it only supports single line
comments

.
endif
" Multiline comment ends

