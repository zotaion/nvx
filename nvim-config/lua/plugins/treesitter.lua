-- Treesitter configuration (parsers provided by Nix withAllGrammars)
do
    -- gain access to the treesitter config functions
    local ts_config = require("nvim-treesitter")

    -- call the treesitter setup function with properties to configure our experience
    ts_config.setup({
        -- Nix provides all grammars, no need to ensure_installed
        ensure_installed = {},
        auto_install = false,
        -- make sure highlighting is enabled
        highlight = { enable = true },
        -- enable tsx auto closing tag creation
        autotag = {
            enable = true
        },
        -- Disable the ts_context_commentstring module integration via treesitter
        -- We handle it directly in the Comment.nvim config with pcall protection
        context_commentstring = {
            enable = false,
            enable_autocmd = false,
        },
    })

    -- Configure ts_context_commentstring directly - disable the CursorHold autocmd
    -- which errors on filetypes without a treesitter parser.
    -- Comment.nvim's pre_hook (wrapped in pcall) handles commentstring detection instead.
    require("ts_context_commentstring").setup({
        enable_autocmd = false,
    })
end
