""" Plug """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"call plug#begin('~/.local/share/nvim/plugged')
call plug#begin(stdpath('data') . '/plugged')

" git
Plug 'tpope/vim-git'
Plug 'tpope/vim-fugitive'
Plug 'gregsexton/gitv'
Plug 'lewis6991/gitsigns.nvim'

" movement
Plug 'unblevable/quick-scope'
Plug 'ap/vim-you-keep-using-that-word'  " disables cw/cW exception of not including the space(s) after word

" sessions and such
Plug 'tpope/vim-obsession'
Plug 'dhruvasagar/vim-prosession'
Plug '907th/vim-auto-save'
Plug 'simnalamburt/vim-mundo'
Plug 'moll/vim-bbye'

" fuzzy search
Plug 'Yggdroot/LeaderF', { 'do': './install.sh' }
Plug 'tamago324/LeaderF-filer'
"
" general programming and completion
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer', { 'branch': 'main' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'nvim-treesitter/nvim-treesitter-refactor'
" completion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lua'
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'

Plug 'machakann/vim-sandwich'  " replaces vim-surround below
Plug 'towolf/vim-helm'
" Plug 'tpope/vim-surround'  " replaced by vim-sandwich
Plug 'tpope/vim-repeat'
"Plug 'juliosueiras/vim-terraform-completion'
"Plug 'hashivim/vim-terraform', { 'for': 'terraform' }
Plug 'Shougo/deoplete.nvim', { 'for': 'terraform' }
Plug 'tmsvg/pear-tree' " auto-close parens etc, replaces delimitmate
Plug 'tpope/vim-commentary'
Plug 'junegunn/vim-easy-align'

" themes, colors, etc
"Plug 'stevearc/dressing.nvim'
Plug 'nvim-telescope/telescope-ui-select.nvim'
"Plug 'vim-scripts/Solarized'
"Plug 'vim-airline/vim-airline'
"Plug 'vim-airline/vim-airline-themes'
"Plug 'ryanoasis/vim-devicons'
"Plug 'shaunsingh/solarized.nvim'
Plug 'feline-nvim/feline.nvim'
Plug 'kyazdani42/nvim-web-devicons'
"Plug 'overcache/NeoSolarized'
Plug 'ishan9299/nvim-solarized-lua'
" Initialize plugin system
call plug#end()
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" ==========================================================
" Basic Settings
" ==========================================================
syntax on                     " syntax highlighing
filetype on                   " try to detect filetypes
filetype plugin indent on     " enable loading indent file for filetype
set number                    " Display current line number
set relativenumber            " Display line numbers relative to current line
set numberwidth=1             " using only 1 column (and 1 spa4e) while possible
" set background=dark           " We are using dark background in vim
set title                     " show title in console title bar
set wildmenu                  " Menu completion in command mode on <Tab>
set wildmode=longest,list,full             " <Tab> cycles between all matching choices.
set wildignorecase
set signcolumn=yes
" don't bell or blink
set noerrorbells
set vb t_vb=

" Ignore these files when completing
set wildignore+=*.o,*.obj,.git,*.pyc

" Set working directory
nnoremap <leader>. :lcd %:p:h<CR>

" undo
set undolevels=1000
if has('persistent_undo')
    " silent !mkdir -p stdpath('data') . '/undo' > /dev/null 2>&1
    call mkdir(stdpath('data') . '/undo', 'p')
    "set undodir = stdpath('data') . '/undo'
    let &undodir=stdpath('data') . '/undo'
    set undofile
endif


""" Moving Around/Editing
set cursorline              " have a line indicate the cursor location
set ruler                   " show the cursor position all the time
set colorcolumn=80          " show a line at column 80
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
set hidden                  " allows buffers to be hidden when modified
set ssop-=options           " do not store global and local values in a session
set ssop-=folds             " do not store folds
" inc/dec numbers right of cursor using -/+
set nrformats=
nnoremap + <C-a>
nnoremap - <C-x>
" visual replace
if has("nvim")
    set inccommand=nosplit
endif

au TextYankPost * silent! lua vim.highlight.on_yank{on_visual = false, higroup="IncSearch", timeout=700}
" ==========================================================

let g:python3_host_prog='/usr/bin/python3'

" ==========================================================


" ==========================================================
" vim grep setup using ripgrep
" ==========================================================

if executable('rg')
    set grepprg=rg\ --vimgrep\ --no-heading
    set grepformat^=%f:%l:%c:%m
endif

" ==========================================================


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

" Edit vimr configuration file
"nnoremap <Leader>ce :e $MYVIMRC<CR>
" Reload vimr configuration file
"nnoremap <Leader>cr :source $MYVIMRC<CR>

""" buffers
" new empty buffer
nmap <leader>bn :enew<cr>
nmap <leader>bx :new<cr>
nmap <leader>bd :bdelete<cr>
" Move to the next buffer
nmap <leader>l :bnext<CR>
" Move to the previous buffer
nmap <leader>h :bprevious<CR>"

" close all buffers except current
command! BufOnly execute '%bdelete|edit #|normal `"'

" ctrl-jklm changes to window split in that direction
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" and lets make these all work in insert mode too ( <C-O> makes next cmd
"  happen as if in command mode )
imap <C-W> <C-O><C-W>

" Paste from clipboard
map <leader>v "+gP

" Quit window on <leader>q
nnoremap <leader>q :q<CR>
"
" Quit all windows on <leader>Q
nnoremap <leader>Q :qall<CR>
"
" hide matches on <leader>space
nnoremap <leader><space> :nohlsearch<cr>

" Remove trailing whitespace on <leader>backspace
"nnoremap <leader>S :%s/\s\+$//<cr>:let @/=''<CR>
nnoremap <leader><BS> :%s/\s\+$//<cr>:let @/=''<CR>


" ==========================================================
"
"
"
" PLUGINS CONFIG BELOW
"
"
"
"
" ==========================================================


" ==========================================================
" sessions - vim-obsession and vim-prosession
" ==========================================================

let g:prosession_dir = '~/.config/nvim/session'
let g:prosession_on_startup = 1

" ==========================================================
" autosave (disabled for now)
" ==========================================================

let g:auto_save        = 0
let g:auto_save_silent = 1
let g:auto_save_events = ["InsertLeave", "TextChanged", "FocusLost"]
" let g:auto_save_write_all_buffers = 1  " write all open buffers as if you would use :wa

" ==========================================================
" Mundo
" ==========================================================
nnoremap <F5> :MundoToggle<CR>


" ==========================================================
" quick-scope
" ==========================================================
" Trigger a highlight in the appropriate direction when pressing these keys:
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
" Trigger a highlight only when pressing f and F.
"let g:qs_highlight_on_keys = ['f', 'F']

" ==========================================================
" leaderf, fuzzy search
" ==========================================================
" don't show the help in normal mode
let g:Lf_HideHelp = 1
" disable cache as it can't locate newly created files
let g:Lf_UseMemoryCache = 0
let g:Lf_UseCache = 0
let g:Lf_IgnoreCurrentBufferName = 1
let g:Lf_UseVersionControlTool = 1
let g:Lf_RecurseSubmodules = 1
let g:Lf_WorkingDirectoryMode = 'Ac' "search from git repo root
let g:Lf_RootMarkers = ['.git']
let g:Lf_CacheDirectory = '/home/chrisq/.cache/LfCache'
" popup mode
let g:Lf_WindowPosition = 'popup'
let g:Lf_PreviewInPopup = 1
let g:Lf_StlSeparator = { 'left': "\ue0b0", 'right': "\ue0b2", 'font': "DejaVu Sans Mono for Powerline" }
let g:Lf_PreviewResult = {'Function': 0, 'BufTag': 0 }
let g:Lf_ShowHidden = 1

let g:Lf_ShortcutF = "<leader>ff"
noremap <leader>fb :<C-U><C-R>=printf("Leaderf buffer %s", "")<CR><CR>
noremap <leader>fm :<C-U><C-R>=printf("Leaderf mru %s", "")<CR><CR>
noremap <leader>ft :<C-U><C-R>=printf("Leaderf bufTag %s", "")<CR><CR>
noremap <leader>fl :<C-U><C-R>=printf("Leaderf line %s", "")<CR><CR>

noremap <C-B> :<C-U><C-R>=printf("Leaderf! rg --current-buffer -e %s ", expand("<cword>"))<CR>
noremap <C-F> :<C-U><C-R>=printf("Leaderf! rg -e %s ", expand("<cword>"))<CR>
" search visually selected text literally
noremap gf :<C-U><C-R>=printf("Leaderf! rg -F -e %s ", leaderf#Rg#visual())<CR>
noremap go :<C-U>Leaderf! rg --recall<CR>

" should use `Leaderf gtags --update` first
let g:Lf_GtagsAutoGenerate = 0
let g:Lf_Gtagslabel = 'native-pygments'
noremap <leader>fr :<C-U><C-R>=printf("Leaderf! gtags -r %s --auto-jump", expand("<cword>"))<CR><CR>
noremap <leader>fd :<C-U><C-R>=printf("Leaderf! gtags -d %s --auto-jump", expand("<cword>"))<CR><CR>
noremap <leader>fo :<C-U><C-R>=printf("Leaderf! gtags --recall %s", "")<CR><CR>
noremap <leader>fn :<C-U><C-R>=printf("Leaderf gtags --next %s", "")<CR><CR>
noremap <leader>fp :<C-U><C-R>=printf("Leaderf gtags --previous %s", "")<CR><CR>

" custom mappings
"noremap <leader>/ :<C-U><C-R>=printf("Leaderf rg -e %s", "")<CR><CR>
noremap <leader>fg :<C-U><C-R>=printf("Leaderf rg")<CR><CR>
"" LeaderF - filer
let g:Lf_FilerShowPromptPath = 1
noremap <leader>fc :<C-U><C-R>=printf("Leaderf filer" )<CR><CR>


" ==========================================================
" Treesitter, lsp etc
" ==========================================================

" >> Lsp key bindings
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> <C-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> gi    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> gf    <cmd>lua vim.lsp.buf.formatting()<CR>
nnoremap <silent> gn    <cmd>lua vim.lsp.buf.rename()<CR>

" >> telescope
nnoremap <Leader>pp <cmd>lua require'telescope.builtin'.builtin{}<CR>

" most recently used files
nnoremap <Leader>m <cmd>lua require'telescope.builtin'.oldfiles{}<CR>

" find buffer
nnoremap ; <cmd>lua require'telescope.builtin'.buffers{}<CR>

" find in current buffer
nnoremap <Leader>/ <cmd>lua require'telescope.builtin'.current_buffer_fuzzy_find{}<CR>

" bookmarks
nnoremap <Leader>' <cmd>lua require'telescope.builtin'.marks{}<CR>

" git files
nnoremap <Leader>f <cmd>lua require'telescope.builtin'.git_files{}<CR>

" all files
nnoremap <Leader>bfs <cmd>lua require'telescope.builtin'.find_files{}<CR>

" ripgrep like grep through dir
nnoremap <Leader>rg <cmd>lua require'telescope.builtin'.live_grep{}<CR>

" pick color scheme
nnoremap <Leader>cs <cmd>lua require'telescope.builtin'.colorscheme{}<CR>



" ==========================================================
"
""""" Colors, themes """""""""""
"
" ==========================================================
"
" ==========================================================
""" vim-airline
" ==========================================================
"
" displays all buffers when there's only one tab open
"let g:airline#extensions#tabline#enabled = 1
" only show buffers
"let g:airline#extensions#tabline#fnamemod = ':t'
"let g:airline_powerline_fonts = 1
"if !exists('g:airline_symbols')
"    let g:airline_symbols = {}
"endif
"let g:airline_theme='solarized'

""" solarized
"set t_Co=256
set termguicolors
set background=dark
"let g:solarized_termcolors=16
"colorscheme solarized
"colorscheme NeoSolarized

"if &term =~ '256color'
    " disable Background Color Erase (BCE) so that color schemes
    " render properly when inside 256-color tmux and GNU screen.
    " see also http://sunaku.github.io/vim-256color-bce.html
"    set t_ut=
"endif

lua <<EOF
require("cqconf")
require("lsp")
require("treesitter")
require("completion")
EOF

lua <<EOF
require'nvim-treesitter.configs'.setup {
  refactor = {
    highlight_definitions = {
      enable = true,
      -- Set to false if you have an `updatetime` of ~100.
      clear_on_cursor_move = true,
    },
    highlight_current_scope = { enable = true },
        smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = "grr",
      },
    },
  },
}
EOF
