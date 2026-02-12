return {
    "folke/which-key.nvim",
    enabled = true,
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 1000
    end,
    opts = {
    },
    key = {
        {
            "<Space>?",
            function()
                require("which-key").show({global = false})
            end,
            desc = "Buffer Local Keymaps (which-key)"
        }
    }
}
