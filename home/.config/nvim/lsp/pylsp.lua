return {
    cmd = { "pylsp" },
    filetypes = { "python" },
    pycodestyle = {
        enable = true,
        maxLineLength = 120,
        ignore = { "E741" },
    },
    root_markers = {
        ".venv",
        "venv",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
    },
}
