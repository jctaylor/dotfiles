
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open up EXplore"} )  -- \pv is Explore


vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move a visual block down with autoindenting" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move a visual block up with autoindenting" } )
vim.keymap.set("v", ">", ">gv", { desc = "Indent visual block and keep visual" } )
vim.keymap.set("v", "<", "<gv", { desc = "De-indent visual block and keep visual" })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv", { desc = "Move to next search term, and center screen"} )
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever
-- This pastes the current register over the current visual highlight
-- without replacing the buffer (good for manual find and replace)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set( "n", "<C-B>", "<cmd>make<CR>" )  -- makeprg is defined in set.lua

vim.keymap.set("n", "<leader>h", "<C-w>h" )
vim.keymap.set("n", "<leader>j", "<C-w>j" )
vim.keymap.set("n", "<leader>k", "<C-w>k" )
vim.keymap.set("n", "<leader>l", "<C-w>l" )

-- Window motions
vim.keymap.set("n", "<C-h>", "<C-w>h" )
vim.keymap.set("n", "<C-j>", "<C-w>j" )
vim.keymap.set("n", "<C-k>", "<C-w>k" )
vim.keymap.set("n", "<C-l>", "<C-w>l" )
-- vim.keymap.set("n", "<leader><left>",  "<C-w>h" )
-- vim.keymap.set("n", "<leader><down>",  "<C-w>j" )
-- vim.keymap.set("n", "<leader><up>",    "<C-w>k" )
-- vim.keymap.set("n", "<leader><right>", "<C-w>l" )

-- Ctrl - left/right to move through jumplist
vim.keymap.set("n", "<C-Left>", "<C-O>", { desc = "Jump to backward point in jumplist" } )
vim.keymap.set("n", "<C-Right>", "<C-I>", { desc = "Jump to forward in jumplist" } )

-- Alt-arrows to move through open buffers
vim.keymap.set("n", "<M-Right>", ":bnext<CR>", { desc = "Move to the next buffer" } )
vim.keymap.set("n", "<M-Left>", ":bprev<CR>" , { desc = "Move to the previous buffer" })

vim.keymap.set("n", "<f1>", ":Telescope help_tags<CR>", { desc = "Use Telescope fuzzy finding to jump to a help topic" })

vim.keymap.set( "n", "//", ":set nohlsearch<CR>",  { desc = "Turn off search highlight (until the next search)"}) 
vim.keymap.set( "n", "/", ":set hlsearch<CR>/",  { desc = "Turn off search highlight (until the next search)"}) 
