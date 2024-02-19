return {
    { "ranjithshegde/ccls.nvim", },
    config = function()
        local util = require "lspconfig.util"
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local capabilities = cmp_nvim_lsp.default_capabilities()
        local server_config = {
            filetypes = { "c", "cpp", "objc", "objcpp", "opencl" },
            root_dir = function(fname)
                return util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
                    or util.find_git_ancestor(fname)
            end,
            init_options = {
                cache = {
                    directory = vim.env.XDG_CACHE_HOME .. "/ccls/",
                }
            },
            capabilities = capabilities
        }
        require("ccls").setup { lsp = { lspconfig = server_config } }
    end,
}
