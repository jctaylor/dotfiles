return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
            },
            "nvim-tree/nvim-web-devicons",
            "nvim-telescope/telescope-file-browser.nvim",
        },
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")
            local actions = require("telescope.actions")

            telescope.setup({
                defaults = {
                    path_display = { "smart" },
                    mappings = {
                        i = {
                            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                            ["<C-j>"] = actions.move_selection_next,     -- move to next result
                            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                        },
                    },
                    cache_picker = { num_pickers = 4, ignore_empty_prompt = true }
                },
            })

            telescope.load_extension("fzf")

            -- set keymaps
            local keymap = vim.keymap -- for conciseness

            -- files
            keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Open buffers" })
            keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
            keymap.set("n", "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Fuzzy find git tracked files" })
            keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })

            -- grep string
            keymap.set("n", "<leader>gg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep git tracked files" })
            keymap.set("n", "<leader>gs", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
            keymap.set("n", "<leader>gb", function() builtin.grep_string({grep_open_files = true}) end, { desc = "Find string under cursor in open buffers"})

            -- tags
            keymap.set("n", "<leader>tt", "<cmd>Telescope tags<cr>",
                { desc = "List ctags (Assuming there is a tags file)" })
            keymap.set("n", "<leader>tb", "<cmd>Telescope current_buffer_tags<cr>",
                { desc = "List ctags from within current buffer (Assuming there is a tags file)" })

            keymap.set("n", "<leader><leader>", "<cmd>Telescope resume<cr>",
                { desc = "Reopen previous picker in the same state" })

            -- file browsing
            vim.keymap.set('n', '<leader>e.', ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
                { desc = "File browser current dir" })
            vim.keymap.set('n', '<leader>ee', ":Telescope file_browser", { desc = "File browse project" })

            -- marks and jumplist
            vim.keymap.set('n', '<leader>m', "<cmd>Telescope marks<cr>", { desc = "Mark locations" })
            vim.keymap.set('n', '<leader>j', "<cmd>Telescope jumplist<cr>", { desc = "Jump locations" })

            -- LSP
            vim.keymap.set('n', '<leader>lr', "<cmd>Telescope lsp_references<cr>", { desc = "LSP references" })
            -- vim.keymap.set('n', '<leader>lo', "<cmd>Telescope lsp_outgoing_calls<cr>", { desc = "LSP outgoing calls" })
            --vim.keymap.set('n', '<leader>lr', "<cmd>Telescope lsp_incoming_calls<cr>", { desc = "LSP incoming calls" })
            vim.keymap.set('n', '<leader>lo', "<cmd>Telescope diagnostics<cr>", { desc = "LSP diagnostics" })
        end,
    },
}
