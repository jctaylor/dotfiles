-- Global lsp setup
-- see: https://gpanders.com/blog/whats-new-in-neovim-0-11/

vim.lsp.enable( { 
    'clangd',
    'pylsp',
    'lua_ls',
    'bashls',
} )


vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

