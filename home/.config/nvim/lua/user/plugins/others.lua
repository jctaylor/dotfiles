return {

    "nvim-lua/plenary.nvim", -- lua functions that many plugins use

    "christoomey/vim-tmux-navigator", -- tmux & split window navigation
    -- 'alexghergh/nvim-tmux-navigation',

    "inkarkat/vim-ReplaceWithRegister", -- replace with register contents using motion (gr + motion)

}

--[====[
:r
if vim.g.vscode then
else
    -- Bootstrap lazy.nvim
    -- This just installs if it is not found
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable", -- latest stable release
            lazypath,
        })
    end
    vim.opt.rtp:prepend(lazypath)

    -- List plugins for lazy.nvim to manage here
    plugins = {

        -- Color
        { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

        -- Telescope
        { 'nvim-telescope/telescope.nvim', dependencies  = { { 'nvim-lua/plenary.nvim' } } },
        { 'nvim-telescope/telescope-file-browser.nvim', dependencies  = { { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' } } },
        { 'nvim-telescope/telescope-fzf-native.nvim', dependencies  = { { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' } } },
        { 'debugloop/telescope-undo.nvim', dependencies = { { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' } } },
        { 'yagiziskirik/AirSupport.nvim' },  -- use telescope to see and choose shortcuts
        { 'ahmedkhalf/project.nvim' },  -- cd to project directory, integrates eith telescope

        -- Treesitter
        { 'nvim-treesitter/playground', { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'  } },


        -- Tools
        { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
        { 'theprimeagen/harpoon' },  -- Make a global Mark list
        { 'mbbill/undotree' },      -- Persistent undotree
        { 'nvim-neo-tree/neo-tree.nvim' },
        { 'simrat39/symbols-outline.nvim' },

        -- git
        { 'tpope/vim-fugitive' },       -- interact with git
        { 'sindrets/diffview.nvim' },   -- git diff visualization
        { 'f-person/git-blame.nvim' },  -- inline git blame
        { 'petertriho/cmp-git' },


        -- LSP and autocompletion
        { 'hrsh7th/nvim-cmp' },     -- nvim completion
        { 'hrsh7th/cmp-buffer' },
        { 'hrsh7th/cmp-path' },
        { 'hrsh7th/cmp-cmdline' },
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'hrsh7th/cmp-vsnip' },
        { 'hrsh7th/vim-vsnip' },
        -- { 'hrsh7th/vim-vsnip-integ' },
        { 'neovim/nvim-lspconfig' },  -- Manage LSP servers

        -- Manage LSP tools external to nvim
        { 'williamboman/mason.nvim' },
        { 'williamboman/mason-lspconfig.nvim' },


        -- C/C++ support
        { 'microsoft/vscode-cpptools' },


        -- python support
        { 'microsoft/debugpy' },
        { 'microsoft/pyright' },
        { 'nvie/vim-flake8' },
        { 'pappasam/jedi-language-server' },


        -- bash support
        { 'bash-lsp/bash-language-server' },
        { 'rogalmic/vscode-bash-debug' },


        -- protobuf support
        { 'bufbuild/buf' },
        { 'bufbuild/buf-language-server' },

        { 'mfussenegger/nvim-lint' },  -- complimentary to LSP linting?

        { 'vimwiki/vimwiki' },

        { 'alexghergh/nvim-tmux-navigation' },

        -- { 'rose-pine/neovim', as = 'rose-pine', config = function() vim.cmd('colorscheme slate') end },
        -- { 'neoclide/coc.nvim' },  -- I think this collides with cmp-nvim-lsp
        -- { 'clangd/coc-clangd', dependencis = { 'noeclide/coc.nvim' } },
        -- { 'pappasam/coc-jedi' },
        -- { 'paopaol/telescope-git-diffs.nvim' }, -- seems to be tiny project much smaller than sindrets/diffview.nvim

    }

    -- See lazy.nvim config schema
    opt = { }

    --vim.g.mapleader = '\\'   -- Leader needs to be defined before lazy startup
    vim.g.mapleader = ' '   -- Leader needs to be defined before lazy startup

    require('lazy').setup( plugins, opt  )

end
--]====]
