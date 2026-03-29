return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "mfussenegger/nvim-dap-python",
    "nvim-neotest/nvim-nio", -- Required for dap-ui
  },
  config = function()
    local dap = require("dap")
    local ui = require("dapui")
    local home = vim.env.HOME  -- my invention. Do I need to do this?

    require("dapui").setup()
    require("dap-python").setup(home .. "/.local/share/pipx/venvs/debugpy/bin/python")

    -- Automatically open/close UI when debugging starts/ends
    dap.listeners.before.attach.dapui_config = function() ui.open() end
    dap.listeners.before.launch.dapui_config = function() ui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() ui.close() end
    dap.listeners.before.event_exited.dapui_config = function() ui.close() end
  end
}
--[[
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
--]]
