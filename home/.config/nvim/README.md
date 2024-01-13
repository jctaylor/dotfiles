# vimconfig
My vim comfig

2025-12-15 Lets do this again for nvim 0.11

Goals:
    * LSP for lua, python, C/C++
    * Formatters for the same
    * LSP completion
    * snippets completion
    * 
    * DAP debug and DAP-UI
    * no Mason
    * no Mason-lspconfig
    * no nvim-lspconfig
    * good completion (use luasnip for snippets)
    * use blink.nvim instead of nvim-cmp.nvim (blink is supposed to be faster and easier to config).

Folke's snacks? Does this bring in too much?


none-lsp.nvim  -- To add 
lazydev.nvim -- So LSP works properly when editing nvim config files (vim global is known and expansions).

## References

https://gpanders.com/blog/whats-new-in-neovim-0-11/#lspa
https://lugh.ch/switching-to-neovim-native-lsp.html
https://github.com/josean-dev/dev-environment-files/tree/main/.config/nvim


## Mason, Mason-lspconfig, nvim-lspconfig

Mason is a packaged manager for external LSP and LSP-related packages
nvim-lspconfig contains a set of good default LSP configurations for many LSP
mason-lspconfig  automatically configures LSPs loaded by Mason (and provides some more LSP configs apparently)

Without this trio, I need to:
    1. Install LSPs manually. Refer to [Mason registry](https://mason-registry.dev/registry/list) to find an LSP.
    2. Put LSP config in .config/nvim/lsp/<LSP-name>.lua
    3. Add enable <LSP-name> in .config/nvim/user/lsp.lua

## lazydev (for good LSP support when editing nviom configs)

folke/lazydev.nvim -- tweaks Lua LSP for editing .config/nvim/  (i.e. global "vim" symbol)





## Priorities:

Plugin manager 
    * folke/lazy.nvim

Project file navigation
    * telescope
    What's the difference between 

LSP support 
    * neovim/nvim-lspconfig
    * williamboman/mason.nvim
    * williamboman/mason-lspconfig.nvim

Completion
    * hrsh7th/nvim-cmp
        * hrsh7th/cmp-buffer
        * hrsh7th/cmp-path
        * hrsh7th/cmp-cmdline
        * L3MON4D3/LuaSnip
        * saadparwaiz1/cmp_luasnip
        * rafamadriz/friendly-snippets

Syntax highlight
    * nvim-treesitter/nvim-treesitter
    * nvim-treesitter/nvim-treesitter-textobjects
    * windwp/nvim-ts-autotag

Color scheme
    * catppuccin/nvim

omnifunctions are filetype specific functions that provide completion suggestions.


## Key maps

Finding files or strings in files:

    * find git cached files
    * find by file type (python, C, lua, etc.)
    * cross product git ( cached X type )

    <leader>fga -- File Git any
    <leader>fgp -- File Git python
    <leader>fgc -- File Git C/C++ (.c, .cpp, .h)
    <leader>fgm -- File Git Markdown

    <leader>saa -- String Any any
    <leader>sap -- String Any python
    <leader>sac -- String Any C/C++ (.c, .cpp, .h)
    <leader>sam -- String Any Markdown

Picker to choose anyother picker:

    Picker that offers the a choice of the above.
    <leader>ff -- Open a picker that first selects the file-set (git-any, git-c, any-any, etc.)
    <leader>fs -- Open a picker that first selects the file-set (git-any, git-c, any-any, etc.) for string to find

Picker jump to marks (harpoon-ish?)

    <leader>jf -- Choose one of the marks from the worktree
    <leader>jb -- Choose one of the marks in the current buffer


### Moving within a file

key maps


## Key maps

### search in buffer

'/' --- vim builtin to start search, also a keymap that turns on highlighting if no other key is pressed to timeoutlen
        milliseconds.
'//' -- turn off search highlight

### Finding files

Use Telescope to find files

    1.) Find git tracked files
    2.) Find file within CWD tree
    3.) Open a file explorer
    4.) Find files based on some sort of project file set. Maybe have a project 
    5.) Find files based on file-type (.c, .py, .md, etc.), in this case, by git,cwd,file-set ?

What about a single find file keymap, that finds files based on the currently selected file set.
File sets could be 
    
    * all git tracked files
    * files of a particular type (.c, .cpp, .h, .py, .lua etc.)
    * files within CWD tree
    * union or intersection of theses sets

To do this, we need an easy way to specify the sets:
    * Telescope picker
    * (type, location) string tuple (location being git, CWD)

==> Create a popup that allows us to quickly define the search sets

Maybe seperate search set from find file command.  Set the scope (git, git-x-filetype, cwd, ...) in a global
variable, then a single Telescope picker to find files within the 

### Moving/jumping

    * jump to file markers
    * jump to diagnostics (LSP errors etc., quick fix)
    * 

### Taking actions

    * LSP quick fix
    * LSP format
    * build project
    * 
    

Finding files or strings in files:


    * find git cached files
    * find by file type (python, C, lua, etc.)
    * cross product git ( cached X type )

    <leader>fga -- File Git any
    <leader>fgp -- File Git python
    <leader>fgc -- File Git C/C++ (.c, .cpp, .h)
    <leader>fgm -- File Git Markdown

    <leader>saa -- String Any any
    <leader>sap -- String Any python
    <leader>sac -- String Any C/C++ (.c, .cpp, .h)
    <leader>sam -- String Any Markdown

Picker to choose anyother picker:

    Picker that offers the a choice of the above.
    <leader>ff -- Open a picker that first selects the file-set (git-any, git-c, any-any, etc.)
    <leader>fs -- Open a picker that first selects the file-set (git-any, git-c, any-any, etc.) for string to find

Picker jump to marks (harpoon-ish?)

    <leader>jf -- Choose one of the marks from the worktree
    <leader>jb -- Choose one of the marks in the current buffer

### Moving within a file

Get rid of dependency on Mason. Install LSPs, formatters, and linters manually.

### pip vs pipx

https://betterstack.com/community/guides/scaling-python/pip-vs-pipx/


### Neovim node.js client

See [node-client doc](https://neovim.io/node-client/)
```
npm install -g neovim
```
