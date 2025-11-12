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
-- Detach ts_ls from HTML files if it somehow attaches
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        
        -- If ts_ls attached to an HTML file, detach it
        if client and client.name == "ts_ls" and bufname:match("%.html$") then
            vim.lsp.buf_detach_client(args.buf, client.id)
        end
    end,
})
