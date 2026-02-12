-- none-ls provides diagnostics, code formatting, refactoring via the builtin in LSP client
return {
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvimtools/none-ls-extras.nvim"
        },
        opts = function(_, opts)
            local null_ls = require("null-ls")
            opts.root_dir = opts.root_dir
            or require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
            opts.sources = vim.list_extend(opts.sources or {}, {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.completion.spell,
                null_ls.builtins.formatting.black,  -- @TODO change this to blackd (single server for nvim instances)
                null_ls.builtins.code_actions.refactoring, -- requires visually selecting the code you want to refactor and calling :'<,'>lua vim.lsp.buf.code_action()
                null_ls.builtins.diagnostics.mypy.with({  -- mypy needs to be told where the python executable is to find imports
                    extra_args = function()
                        local venv_path = os.getenv("VIRTUAL_ENV") or "/usr"
                        return { "--python-executable", venv_path .. "/bin/python" }
                    end,
                }),
                -- Consider adding isort/isortd, mypy
            })
        end,

    }
}
