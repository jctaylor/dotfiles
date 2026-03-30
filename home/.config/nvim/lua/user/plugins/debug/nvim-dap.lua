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

        vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
        vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
        vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
        vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
        vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
        vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
        vim.keymap.set('n', '<Leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
        vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
        vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
        vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
            require('dap.ui.widgets').hover()
        end)
        vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
            require('dap.ui.widgets').preview()
        end)
        vim.keymap.set('n', '<Leader>df', function()
            local widgets = require('dap.ui.widgets')
            widgets.centered_float(widgets.frames)
        end)
        vim.keymap.set('n', '<Leader>ds', function()
            local widgets = require('dap.ui.widgets')
            widgets.centered_float(widgets.scopes)
        end)
        vim.fn.sign_define('DapBreakpoint', {text='🛑', texthl='', linehl='', numhl=''})
        vim.fn.sign_define('DapStopped', {text='▶', texthl='Question', linehl='', numhl=''})
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
