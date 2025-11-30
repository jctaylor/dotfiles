-- Completion
-- see :help cmp
return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        -- "neovim/nvim-lspconfig", -- not needed in nvim 0.11
        "hrsh7th/cmp-nvim-lsp", -- get completions from LSPs
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-cmdline", -- command line 
        "hrsh7th/cmp-path", -- source for file system paths

        -- A snippet engine is required...

        -- For vsnip users.
        -- "hrsh7th/cmp-vsnip",
        -- "hrsh7th/vim-vsnip",

        -- For luasnip users.
        { "L3MON4D3/LuaSnip", run = "make install_jsregexp" },
        "saadparwaiz1/cmp_luasnip",

        -- For mini.snippets users.
        --  "echasnovski/mini.snippets",
        --  "abeldekat/cmp-mini-snippets",

        -- For snippy users.
        --  "dcampos/nvim-snippy",
        --  "dcampos/cmp-snippy",

        -- For ultisnips users.
        --  "SirVer/ultisnips",
        --  "quangnguyen30192/cmp-nvim-ultisnips",


        "rafamadriz/friendly-snippets", -- useful snippets
    },
    config = function()

        require("luasnip").setup()

        -- Set up nvim-cmp.
        local cmp = require'cmp'

        cmp.setup({
            snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
                    -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
                    -- vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
                end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                ["<Tab>"] = cmp.mapping(function(fallback)
                    -- This little snippet will confirm with tab, and if no entry is selected, will confirm the first item
                    if cmp.visible() then
                        local entry = cmp.get_selected_entry()
                        if not entry then
                            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                        else
                            cmp.confirm()
                        end
                    else
                        fallback()
                    end
                end, { "i", "s", "c", }),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'vsnip' }, -- For vsnip users.
                -- { name = 'luasnip' }, -- For luasnip users.
                -- { name = 'snippy' }, -- For snippy users.
                -- { name = 'ultisnips' }, -- For ultisnips users.
            },
                {
                    { name = 'buffer' },
                })
        })

        -- `/` cmdline setup.
        cmp.setup.cmdline('/', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = 'buffer' }
          }
        })

        -- `:` cmdline setup.
        cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = 'path' }
            }, {
                    { name = 'cmdline' }
                }),
            matching = { disallow_symbol_nonprefix_matching = false }
        })
        -- Set configuration for specific filetype.
        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({
                { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
            }, {
                    { name = 'buffer' },
                })
        })


    end,
}
