# vimconfig
My vim comfig


## Priorites:

telescope
LSP
treesitter
good colorscheme

key maps


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

Get rid of dependency on Mason. Install LSPs, formatters, and linters manually.


