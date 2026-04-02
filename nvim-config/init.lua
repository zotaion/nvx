-- nvx - Nix-managed Neovim configuration
-- All plugins are provided via Nix, no runtime plugin manager needed
vim.g.have_nerd_font = true
require('vim._core.ui2').enable()
-- Suppress specific deprecation warnings
local notify_original = vim.notify
vim.notify = function(msg, ...)
    if
        msg
        and (
            msg:match 'position_encoding param is required'
            or msg:match 'Defaulting to position encoding of the first client'
            or msg:match 'multiple different client offset_encodings'
            or msg:match 'lspconfig.*framework.*is deprecated'
        )
    then
        return
    end
    return notify_original(msg, ...)
end

-- Suppress vim.deprecate warnings for lspconfig
local deprecate_original = vim.deprecate
vim.deprecate = function(name, alternative, version, plugin, ...)
    if plugin and plugin:match('lspconfig') then
        return
    end
    return deprecate_original(name, alternative, version, plugin, ...)
end


require("config.neovide")
-- Load the options from the config/options.lua file
require("config.options")
-- Load the keymaps from the config/keymaps.lua file
require("config.keymaps")
-- Load the auto commands from the config/autocmds.lua file
require("config.autocmds")
-- Load Angular-specific configuration
require("config.angular")
-- Load Rust-specific configuration
require("config.rust")
-- Load Svelte-specific configuration
require("config.svelte")

-- Setup all plugins (Nix provides them, we just configure)
require("plugins.colorscheme")
require("plugins.telescope")
require("plugins.lsp-config")
require("plugins.treesitter")
require("plugins.cmp")
require("plugins.nvim-dap")
require("plugins.lualine")
require("plugins.harpoon")
require("plugins.git")
require("plugins.oil")
require("plugins.flash")
require("plugins.fmt")
require("plugins.comment")
require("plugins.autopairs")
require("plugins.surround")
require("plugins.smartsplit")
require("plugins.neoscroll")
require("plugins.supermaven")
-- Disabled due to autocmd errors on non-Spring Boot Java files
-- Users can manually enable by uncommenting this line
-- require("plugins.springboot-nvim")
require("plugins.opencode")
require("plugins.whichkey")
require("plugins.diffview")
require("plugins.render-markdown")
