-- Setup our JDTLS server any time we open up a java file
vim.cmd [[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require'config.jdtls'.setup_jdtls()
    augroup end
]]

-- Debug command to show diagnostics with source information
vim.api.nvim_create_user_command('ShowDiagnostics', function()
    local diagnostics = vim.diagnostic.get(0)
    for _, diag in ipairs(diagnostics) do
        print(string.format(
            "Code: %s, Source: %s, Message: %s",
            diag.code or "nil",
            diag.source or "nil",
            diag.message
        ))
    end
end, {})
