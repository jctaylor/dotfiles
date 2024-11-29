-- General nvim options

vim.opt.backup = false
vim.opt.clipboard = "unnamedplus"
vim.opt.cmdheight = 2
vim.opt.conceallevel = 0
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.fileencoding = "utf-8"
vim.opt.hlsearch = true
vim.opt.ignorecase = false
vim.opt.incsearch = true
vim.opt.isfname:append("@-@")
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.numberwidth = 4
vim.opt.relativenumber = false
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 4
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = true
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.timeoutlen = 2000  -- Timeout for partial keymap sequences e.g. <leader>ff
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.updatetime = 50
vim.opt.whichwrap = "bs<>[]hl"
vim.opt.wrap = true
vim.opt.writebackup = false
vim.opt.colorcolumn = "120" -- This is a string. In general it is a list of columns seperated by commas


vim.api.nvim_create_user_command('WQ', 'wq', {})
vim.api.nvim_create_user_command('Wq', 'wq', {})
vim.api.nvim_create_user_command('W', 'w', {})
vim.api.nvim_create_user_command('Qa', 'qa', {})
vim.api.nvim_create_user_command('Q', 'q', {})



vim.opt.listchars = "tab:——▷,trail:⎵,extends:⟩,precedes:⟨,space:"
    --  
    --   

-- ▻   ▷
-- ❭❯ ➖ \udb81\udf94  —— °🡲 🡲⭘  ⎵
