# vimconfig

## Testing

When working on nvim config inside dotfiles
make sure there is a symbolic link in ~/.config/nvimtest ---> ~/dotfiles/.../nvim
then start nvim like this ...

```
NVIM_APPNAME=nvimtest nvim
```


## References

https://gpanders.com/blog/whats-new-in-neovim-0-11/#lspa
https://lugh.ch/switching-to-neovim-native-lsp.html
https://github.com/josean-dev/dev-environment-files/tree/main/.config/nvim


## Mason, Mason-lspconfig, nvim-lspconfig

Mason is a packaged manager for external LSP and LSP-related packages
nvim-lspconfig contains a set of good default LSP configurations for many LSP
mason-lspconfig  automatically configures LSPs loaded by Mason (and provides some more LSP configs apparently)

Without this trio, I need to:
    1. Install LSPs manually. Refer to [Mason registry](https://mason-registry.dev/registry/list) to find an LSP.
    2. Put LSP config in .config/nvim/lsp/<LSP-name>.lua
    3. Add enable <LSP-name> in .config/nvim/user/lsp.lua

[ ] Make a list of everything that Mason might install and add it to the dotfiles
    install scripts.

