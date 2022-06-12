-- ==========================================================
-- Basic Settings
-- ==========================================================
local opt = vim.opt -- to set options

-- this needs to be set before all color schemes and so on
vim.o.termguicolors = true

opt.number = true                       -- Display current line number
opt.relativenumber = true               -- Display line numbers relative to current line
opt.numberwidth=1                       -- using only 1 column (and 1 spa4e) while possible
opt.title = true                        -- show title in console title bar
opt.wildmenu = true                     -- Menu completion in command mode on <Tab>
opt.wildmode = "longest,list,full"      -- <Tab> cycles between all matching choices.
opt.wildignorecase = true
opt.ignorecase = true                   -- ignore case when tab completing
opt.signcolumn = "number"
opt.belloff = "all" 	                -- don't bell
opt.vb = false	                        -- or blink
opt.wildignore = "*.o,*.obj,.git,*.pyc" -- Ignore these files when completing
opt.list = true
-- opt.listchars:append("space:⋅")
opt.listchars:append("eol:↴")

-- undo
opt.undolevels=1000
-- TODO
--[[
if has('persistent_undo')
    " silent !mkdir -p stdpath('data') . '/undo' > /dev/null 2>&1
    call mkdir(stdpath('data') . '/undo', 'p')
      "set undodir = stdpath('data') . '/undo'
    let &undodir=stdpath('data') . '/undo'
    set undofile
endif
--]]
--
-- -- Moving Around/Editing
opt.cursorline = true               -- have a line indicate the cursor location
opt.ruler = true                    -- show the cursor position all the time
opt.colorcolumn = "88"              -- show a line at column 88 - match Black
-- -- opt.nostartofline  = true           -- Avoid moving cursor to BOL when jumping around
opt.virtualedit = "block"           -- Let cursor move past the last char in <C-v> mode
opt.scrolloff=3                     -- Keep 3 context lines above and below the cursor
opt.backspace = "indent,eol,start"  -- Allow backspacing over autoindent, EOL, and BOL
opt.showmatch  = true               -- Briefly jump to a paren once it's balanced
opt.wrap  = false                   -- don't wrap text
opt.linebreak  = true               -- don't wrap textin the middle of a word
opt.autoindent  = true              -- always set autoindenting on
opt.tabstop = 4                     -- <tab> inserts 4 spaces
opt.shiftwidth = 4                  -- but an indent level is 4 spaces wide.
opt.softtabstop = 4                 -- <BS> over an autoindent deletes 4 spaces.
opt.expandtab  = true               -- Use spaces, not tabs, for autoindent/tab key.
opt.shiftround  = true              -- rounds indent to a multiple of shiftwidth
-- the below breaks % (matchit)
-- opt.matchpairs = "<:>"              -- show matching <> (html mainly) as well
opt.foldmethod = "indent"           -- allow us to fold on indents
opt.foldlevel = 99                  -- don't fold by default
opt.hidden  = true                  -- allows buffers to be hidden when modified
opt.timeoutlen = 300
opt.nrformats = ""
opt.encoding = "utf-8"
-- -- visual replace
opt.inccommand = "nosplit"
--
-- vim.g.loaded_matchit = 1

-- TODO
--[[
-- opt.ssop-=options                -- do not store global and local values in a session
-- opt.ssop-=folds                  -- do not store folds

au TextYankPost * silent! lua vim.highlight.on_yank{on_visual = false, higroup="IncSearch", timeout=700}

let g:python3_host_prog='/usr/bin/python3'
--]]

