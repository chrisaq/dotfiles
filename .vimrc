set nocompatible               " be iMproved
filetype off                   " required!

"""  vundle plugin manager
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
" let Vundle manage Vundle
" required!
Plugin 'gmarik/vundle'

" My Bundles here:
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
Plugin 'sontek/rope-vim.git'
Plugin 'fs111/pydoc.vim.git'
" Getting pep8 through syntastic
"Bundle 'vim-scripts/pep8.git'
Plugin 'alfredodeza/pytest.vim.git'
Plugin 'jmcantrell/vim-virtualenv'
Plugin 'vim-flake8'
"" jedi is not compatible with youcompleteme
Plugin 'https://github.com/davidhalter/jedi-vim.git'
"" code helpers
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/nerdcommenter'
Plugin 'https://github.com/nathanaelkane/vim-indent-guides.git'
Plugin 'tpope/vim-surround.git'
Plugin 'tpope/vim-repeat.git'
"" Misc scripts
Plugin 'kien/ctrlp.vim'
Plugin 'vim-scripts/The-NERD-tree.git'
Plugin 'sjl/gundo.vim.git'
Plugin 'chrisbra/changesPlugin'
Plugin 'https://github.com/Lokaltog/vim-easymotion.git'
Plugin 'Raimondi/delimitMate'
" replacing ultisnips with neosnips for now
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'https://github.com/Valloric/YouCompleteMe.git'
"Bundle 'ervandew/supertab.git'
"Bundle 'Shougo/neosnippet.git'
"Bundle 'Shougo/neocomplcache'
"" color schemes and appearance
"Plugin 'Lokaltog/vim-powerline'
Plugin 'altercation/vim-colors-solarized'
Plugin 'jnurmine/Zenburn'
Plugin 'https://github.com/nanotech/jellybeans.vim'
Plugin 'https://github.com/sickill/vim-monokai.git'
Plugin 'https://github.com/tomasr/molokai.git'
Plugin 'https://github.com/notpratheek/Pychimp-vim.git'
Plugin 'https://github.com/ambidexterich/mustang.git'
Plugin 'https://github.com/akmassey/vim-codeschool.git'
Plugin 'https://github.com/tpope/vim-vividchalk.git'
Plugin 'https://github.com/jonathanfilip/vim-lucius.git'


""""""""""" REST OF CONFIG

" ==========================================================
" Shortcuts
" ==========================================================
let mapleader=","             " change the leader to be a comma vs slash

" Seriously, guys. It's not like :W is bound to anything anyway.
command! W :w
command! Q :q

" sudo write this
cmap W! w !sudo tee % >/dev/null


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

" Open NerdTree
map <leader>n :NERDTreeToggle<CR>

" Run command-t file search
"map <leader>f :CommandT<CR>

" Ack searching
nmap <leader>a <Esc>:Ack!

" Load the Gundo window
map <leader>u :GundoToggle<CR>

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

""" Insert completion
" don't select first item, follow typing in autocomplete
"set completeopt=menuone,longest,preview
"set pumheight=6             " Keep a small completion window

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
set backspace=2             " Allow backspacing over autoindent, EOL, and BOL
set showmatch               " Briefly jump to a paren once it's balanced
set nowrap                  " don't wrap text
set linebreak               " don't wrap textin the middle of a word
set autoindent              " always set autoindenting on
set smartindent             " use smart indent if there is no indent file
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
set listchars=tab:>-,eol:$,trail:-,precedes:<,extends:>
set list

""" Searching and Patterns
set ignorecase              " Default to using case insensitive searches,
set smartcase               " unless uppercase letters are used in the regex.
set smarttab                " Handle tabs more intelligently 
set hlsearch                " Highlight searches by default.
set incsearch               " Incrementally search while typing a /regex
set gdefault                " Search and replace globally by default.
nmap <silent> ,/ :nohlsearch<CR> " Clear searches by typing ,/"
" use normal regular expressions
nnoremap / /\v
vnoremap / /\v

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
let g:Powerline_symbols = 'fancy'
set encoding=utf-8

"if &t_Co == 256
"         colorscheme desert256
"endif

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
au FileType python setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4 smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class,with
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

" Add the virtualenv's site-packages to vim path
"py << EOF
"import os.path
"import sys
"import vim
"if 'VIRTUALENV' in os.environ:
"    project_base_dir = os.environ['VIRTUAL_ENV']
"    sys.path.insert(0, project_base_dir)
"    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
"    execfile(activate_this, dict(__file__=activate_this))
"EOF
" Load up virtualenv's vimrc if it exists
"if filereadable($VIRTUAL_ENV . '/.vimrc')
"    source $VIRTUAL_ENV/.vimrc
"endif
"
"
" switch between dark and light backgrounds with F12
" http://crunchbang.org/forums/viewtopic.php?id=16105
map <silent> <F12> :if background == "light"<CR>
            \set background=dark<CR>
            \else<CR>
            \set background=light<CR>
            \endif<CR>

"""" autocompletion:
"autocmd FileType python set omnifunc=pythoncomplete#Complete
"autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
"autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
"autocmd FileType css set omnifunc=csscomplete#CompleteCSS
"autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
"autocmd FileType php set omnifunc=phpcomplete#CompletePHP

"" YouComleteMe
let g:ycm_autoclose_preview_window_after_completion=1
nnoremap <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>
" disable tab in ycm as to not interefer with ultisnips, use c-n/c-p
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]

