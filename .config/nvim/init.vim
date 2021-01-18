""" Plug """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"call plug#begin('~/.local/share/nvim/plugged')
call plug#begin(stdpath('data') . '/plugged')

" git
Plug 'tpope/vim-git'
Plug 'tpope/vim-fugitive'
Plug 'gregsexton/gitv'

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

" general programming and completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'machakann/vim-sandwich'  " replaces vim-surround below
" Plug 'tpope/vim-surround'  " replaced by vim-sandwich
Plug 'tpope/vim-repeat'
Plug 'juliosueiras/vim-terraform-completion'
Plug 'hashivim/vim-terraform', { 'for': 'terraform' }
Plug 'Shougo/deoplete.nvim', { 'for': 'terraform' }
Plug 'tmsvg/pear-tree' " auto-close parens etc, replaces delimitmate
Plug 'tpope/vim-commentary'
Plug 'junegunn/vim-easy-align'

" themes, colors, etc
Plug 'vim-scripts/Solarized'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
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


" ==========================================================


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
" autosave
" ==========================================================

let g:auto_save        = 1
let g:auto_save_silent = 1
let g:auto_save_events = ["InsertLeave", "TextChanged", "FocusLost"]
" let g:auto_save_write_all_buffers = 1  " write all open buffers as if you would use :wa

" ==========================================================
" Bbye
" ==========================================================
nnoremap <Leader>q :Bdelete<CR>


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
let g:Lf_UseCache = 0
let g:Lf_UseVersionControlTool = 0
let g:Lf_IgnoreCurrentBufferName = 1
" popup mode
let g:Lf_WindowPosition = 'popup'
let g:Lf_PreviewInPopup = 1
let g:Lf_StlSeparator = { 'left': "\ue0b0", 'right': "\ue0b2", 'font': "DejaVu Sans Mono for Powerline" }
let g:Lf_PreviewResult = {'Function': 0, 'BufTag': 0 }

let g:Lf_ShortcutF = "<leader>ff"
noremap <leader>fb :<C-U><C-R>=printf("Leaderf buffer %s", "")<CR><CR>
noremap <leader>fm :<C-U><C-R>=printf("Leaderf mru %s", "")<CR><CR>
noremap <leader>ft :<C-U><C-R>=printf("Leaderf bufTag %s", "")<CR><CR>
noremap <leader>fl :<C-U><C-R>=printf("Leaderf line %s", "")<CR><CR>

noremap <C-B> :<C-U><C-R>=printf("Leaderf! rg --current-buffer -e %s ", expand("<cword>"))<CR>
noremap <C-F> :<C-U><C-R>=printf("Leaderf! rg -e %s ", expand("<cword>"))<CR>
" search visually selected text literally
xnoremap gf :<C-U><C-R>=printf("Leaderf! rg -F -e %s ", leaderf#Rg#visual())<CR>
noremap go :<C-U>Leaderf! rg --recall<CR>

" should use `Leaderf gtags --update` first
let g:Lf_GtagsAutoGenerate = 0
let g:Lf_Gtagslabel = 'native-pygments'
noremap <leader>fr :<C-U><C-R>=printf("Leaderf! gtags -r %s --auto-jump", expand("<cword>"))<CR><CR>
noremap <leader>fd :<C-U><C-R>=printf("Leaderf! gtags -d %s --auto-jump", expand("<cword>"))<CR><CR>
noremap <leader>fo :<C-U><C-R>=printf("Leaderf! gtags --recall %s", "")<CR><CR>
noremap <leader>fn :<C-U><C-R>=printf("Leaderf gtags --next %s", "")<CR><CR>
noremap <leader>fp :<C-U><C-R>=printf("Leaderf gtags --previous %s", "")<CR><CR>

" ==========================================================
" From CoC
" ==========================================================

" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.

xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <tab> for select selections ranges, needs server support, like: coc-tsserver, coc-python
" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
"set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>


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
let g:airline#extensions#tabline#enabled = 1
" only show buffers
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_theme='solarized'

""" solarized
set t_Co=256
set background=dark
let g:solarized_termcolors=16
colorscheme solarized

"if &term =~ '256color'
    " disable Background Color Erase (BCE) so that color schemes
    " render properly when inside 256-color tmux and GNU screen.
    " see also http://sunaku.github.io/vim-256color-bce.html
"    set t_ut=
"endif
