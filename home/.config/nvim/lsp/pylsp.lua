return {
    cmd = { "pylsp" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".venv", ".git" },
    settings = {
        pylsp = {
            plugins = {
                pycodestyle = { enable = true, ignore = {'W391'}, maxLineLength = 120 },
                -- Add other plugins like flake8, black, or mypy here
            }
        }
    }
}
