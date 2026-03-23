
-- Merge blink.cmp capabilities with builtin capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities = vim.tbl_deep_extend('force', capabilities, require('blink-cmp').get_lsp_capabilities({}, false))

capabilities = vim.tbl_deep_extend('force', capabilities, {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true
    }
  }
})

-- Lua language server
vim.lsp.enable("lua_ls")
vim.lsp.enable("pylsp")
vim.lsp.enable("prolog_lsp")
--vim.lsp.enable('jedi_language_server')
