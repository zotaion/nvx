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
        }
    })
end
