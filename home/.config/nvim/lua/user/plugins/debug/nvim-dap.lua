return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "mfussenegger/nvim-dap-python", 
            "rcarriga/nvim-dap-ui",
        },
        config = function()
            require("dap-python").setup("/home/jason/.local/share/nvim/debugpy/venv/bin/python")
        end,
    },
}

