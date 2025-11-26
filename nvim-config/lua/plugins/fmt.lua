-- Conform formatting configuration
do
    require('conform').setup({
        notify_on_error = false,
        -- Disabled auto-format on save - use <leader>cf to format manually
        -- format_on_save = {
        --     timeout_ms = 500,
        --     lsp_format = 'fallback',
        -- },
        formatters_by_ft = {
            lua = { 'stylua' },
            java = { 'google-java-format' },
            javascript = { 'prettier' },
            typescript = { 'prettier' },
            javascriptreact = { 'prettier' },
            typescriptreact = { 'prettier' },
            ['typescript.tsx'] = { 'prettier' },
            css = { 'prettier' },
            scss = { 'prettier' },
            sass = { 'prettier' },
            html = { 'prettier' },
            json = { 'prettier' },
            yaml = { 'prettier' },
            markdown = { 'prettier' },
            python = { 'autopep8' },
            c = { 'clang-format' },
            cpp = { 'clang-format' },
            rust = { 'rustfmt' },
            svelte = { 'prettier' },
        },
        formatters = {
            ['google-java-format'] = {
                command = 'sh',
                args = {
                    '-c',
                    'google-java-format --aosp - && echo', -- Add newline after formatting
                },
                stdin = true,
            },
            prettier = {
                args = {
                    '--stdin-filepath', '$FILENAME',
                    '--tab-width', '2',  -- Angular convention is 2 spaces
                    '--print-width', '120',
                    '--single-quote', 'true',  -- Angular style guide uses single quotes
                    '--trailing-comma', 'es5',
                    '--arrow-parens', 'always',
                },
            },
            ['clang-format'] = {
                args = { '--style={BasedOnStyle: Microsoft, IndentWidth: 4, TabWidth: 4}' },
            },
            autopep8 = {
                args = { '--max-line-length', '120', '-' },
            },
        },
    })

    -- Manual formatting keybinding: <leader>cf
    -- Formats the current buffer using the configured formatter
    vim.keymap.set('', '<leader>cf', function()
        require('conform').format { async = true, lsp_format = 'fallback' }
    end, { desc = '[C]ode [F]ormat buffer' })
end
