-- Function to cycle through 2 line numbering states
--
NextLineNumberState = function()
    if vim.opt.relativenumber._value then
        -- Relative line number (1) --> regular line numbers
        vim.opt.relativenumber = false
        vim.opt.number = true
    else
        vim.opt.relativenumber = true
        vim.opt.number = true
    end
end

vim.keymap.set('n', '<Space>3', NextLineNumberState, { desc = "Cycle between relative line number, regular line number states"})
