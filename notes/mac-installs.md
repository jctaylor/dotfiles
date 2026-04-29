# Manually installed on Mac

```bash
# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | /bin/sh

# kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh

brew install luajit
brew install luarocks
brew install mypi
brew install mypy     # Maybe get rid of this for ty
brew install numpy
brew install fd
brew install pipx   

pipx install pynvim
pipx install black
pipx install flake8
pipx install mypy    # Maybe obsolete if ty works
pipx install 'python-lsp-server[all]'   # Instead of nvim Mason
pipx install ruff   # astral python lint
pipx install ty     # astral python type checker (much faster than mypy)

brew install rust

npm install -g @mermaid-js/mermaid-cli  # Installs mmdc mermaid-cli for nvim so snacks.nvim can create diagrams in
                                        # a compatible terminal kitty, ghostty, webzo etc.

```

AI gave me the pros and cons of various terminals for mac:

```
For a premium snacks.nvim experience on macOS, all three—Kitty, Wezterm, and Ghostty—are excellent choices because they
support modern terminal features like true color, kitty graphics protocol (for image previews), and fast rendering [1].

Here is a breakdown of which is "better" based on your needs:

1. Ghostty (The Best Overall Choice for Mac) Ghostty is a new terminal emulator written in Zig, built specifically for
   speed and macOS native integration. 

    Why it's better for Snacks.nvim: It has incredible performance and native support for modern terminal features. It
    supports images (for snacks.image) and fast rendering for dashboard/picker UI [1]. Best for: Users who want a fast,
    native-feeling, modern terminal with minimal configuration. 

2. Kitty (The Feature-Rich Choice) Kitty is the standard for modern NeoVim users and has the most mature implementation
   of image protocols. 

    Why it's better for Snacks.nvim: It provides the most robust support for image rendering (snacks.image) and terminal
    graphics. It is extremely fast and heavily optimized for GPU rendering [1]. Best for: Users who want the highest
    compatibility with image/graphical features and extensive customization options. 

3. Wezterm (The Configurable Choice) Wezterm is incredibly powerful, cross-platform, and configured via Lua. 

    Why it's better for Snacks.nvim: It has great support for modern features, but its main advantage is configuration
    flexibility, allowing you to fine-tune how terminal graphics behave. Best for: Users who love Lua configuration and
    want a consistent setup between Mac, Linux, and Windows.
```
