return {
    cmd = { 'clangd', '--background-index' },
    root_markers = { 'compile_commands.json', 'compile_flags.txt' },
    filetypes = { 'c', 'cpp' },
    -- Additional settings for completion or other features can be added here
    settings = {
        clangd = {
            -- Specific clangd settings for completion, e.g., enable snippets
            completion = {
                enableSnippets = true,
            },
        },
    },
}
