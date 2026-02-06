# My dotfiles

## TODO 

[ ] Fix dotfiles.sh so that new config files added in (say .../.config/nvim) are automatically added
Obviously can't do this for $HOME, but most new files in nvim, tmux, etc, are probably meant to be
under version control

[ ] Add a systematic way to add user space packacges
   * npm 
   * pipx
   * cargo (rust)

   On a sync, there should be tests to see if these tools are in the path (installed), and if not should be prompted
   to install



**Very much a work in progress**

The style I use is:

A regular repo (clone into `${HOME}/dotfiles` or something similar)

Run `${HOME}/dotfiles/sync-dotfiles.sh`. This pushes copies of the files into the same relative position as those in the repo.

This will use `ln` to link the files (hard links) into place.



```bash
# python tools installed in user space
pipx install pynvim
pipx install black
pipx install "jupyter[all]"
pipx install flake8
pipx install mypy
pipx install 'python-lsp-server[all]'   # Instead of nvim Mason
pipx install jedi-language-server       # Just for comparison, apparently python-lsp-server is more full featured
pipx install mypy                       # Type checking. This was not easy to configure (needed a --python-executable argument in config)
```

