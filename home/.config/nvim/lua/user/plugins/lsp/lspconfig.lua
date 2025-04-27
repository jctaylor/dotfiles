return {
-- nvim-lspconfig is just a plugin that pulls in a load of default configuration options for the various 
-- LSP servers. This is strictly not necessary, all the options could be configure manually. For example 
-- pylsp aka python-lsp-server configuration options are listed here
-- https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
--
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
--    dependencies = {
--        "hrsh7th/cmp-nvim-lsp",
--    },
    config = function()
        -- import lspconfig plugin
        local lspconfig = require("lspconfig")

        -- These key maps are set when an LSP attaches to a buffer
        -- This on_attach function is passed to each LSP config
        local keymap = vim.keymap -- for conciseness
        local opts = { noremap = true, silent = true }
        local on_attach = function(_, bufnr)
            opts.buffer = bufnr

            -- set keybinds
            opts.desc = "Show LSP references"
            keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

            opts.desc = "Go to declaration"
            keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

            opts.desc = "Show LSP definitions"
            keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

            opts.desc = "Show LSP implementations"
            keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

            opts.desc = "Show LSP type definitions"
            keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

            opts.desc = "See available code actions"
            keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

            opts.desc = "Smart rename"
            keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

            opts.desc = "Show buffer diagnostics"
            keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

            opts.desc = "Show line diagnostics"
            keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

            opts.desc = "Go to previous diagnostic"
            keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

            opts.desc = "Go to next diagnostic"
            keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

            opts.desc = "Show documentation for what is under cursor"
            keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

            opts.desc = "Restart LSP"
            keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

            opts.desc = "Format buffer using LSP"
            keymap.set("n", "<leader>F", vim.lsp.buf.format, opts) -- If capable, format the buffer
        end
        -- import cmp-nvim-lsp plugin

        -- Tell the LSP's that they can add autocomplete suggestions
        local capabilities = require('cmp_nvim_lsp').default_capabilities()

        -- Change the Diagnostic symbols in the sign column (gutter)
        -- (not in youtube nvim video)
        local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " } --    
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end

        -- Configure clangd
        lspconfig["clangd"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        --
        lspconfig["cmake"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        lspconfig["bashls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })


        lspconfig["awk_ls"].setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })



        -- configure graphql language server
        -- lspconfig["graphql"].setup({
        --     capabilities = capabilities,
        --     on_attach = on_attach,
        --     filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        -- })

        -- configure python server
        -- Installed via `pip install pyright`
        --lspconfig["pyright"].setup({
        --    capabilities = capabilities,
        --    on_attach = on_attach,
        --})
        --
        -- pylsp aka python-lsp-server configuration options are listed here
        -- https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md

        lspconfig["pylsp"].setup({
            filetypes = { 'python' },
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
                pylsp = {
                    plugins = {
                        pycodestyle = {
                            maxLineLength = 160
                        },
                        flake8 = {
                            maxLineLength = 160
                        },
                        mccabe = {
                            threshold = 20
                        },
                    }
                }
            }
        })

        -- configure lua server (with special settings)
       -- lspconfig["lua_ls"].setup({
       --     capabilities = capabilities,
       --     on_attach = on_attach,
       --     settings = { -- custom settings for lua
       --         Lua = {
       --             -- make the language server recognize "vim" global
       --             diagnostics = {
       --                 globals = { "vim" },
       --             },
       --             workspace = {
       --                 -- make language server aware of runtime files
       --                 library = {
       --                     [vim.fn.expand("$VIMRUNTIME/lua")] = true,
       --                     [vim.fn.stdpath("config") .. "/lua"] = true,
       --                 },
       --             },
       --         },
       --     },
       -- })
    end,
}
