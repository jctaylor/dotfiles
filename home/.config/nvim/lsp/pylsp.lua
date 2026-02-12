return {
    cmd = { 'python-lsp-server' },
    filetypes = { 'python' },
    root_markers = {
        '.venv',
        'venv',
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        '.git',
    },
}
