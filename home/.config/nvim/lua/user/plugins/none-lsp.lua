-- none-ls provides diagnostics, code formatting, refactoring via the builtin in LSP client
return {
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvimtools/none-ls-extras.nvim",
            "gbprod/none-ls-luacheck.nvim",
        },
        opts = function()
            local null_ls = require("null-ls")  -- Seems weird, see https://github.com/nvimtools/none-ls.nvim
            local root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git", ".venv", "pyproject.toml")
            local sources = {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.completion.spell,
                null_ls.builtins.formatting.black,  -- @TODO change this to blackd (single server for nvim instances)
                null_ls.builtins.code_actions.refactoring, -- requires visually selecting the code you want to refactor and calling :'<,'>lua vim.lsp.buf.code_action()
                null_ls.builtins.diagnostics.mypy.with({  -- mypy needs to be told where the python executable is to find imports
                    extra_args = function()
                        local venv_path = os.getenv("VIRTUAL_ENV") or "/usr"
                        return { "--verbose", "--python-executable", venv_path .. "/bin/python" }
                    end,
                }),
                require("none-ls-luacheck.diagnostics.luacheck"),
            }
            return {
                debug = true,
                sources,
                root_dir
            }
        end,
    }
}
