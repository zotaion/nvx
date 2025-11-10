-- Oil configuration
do
    require("oil").setup({
            -- Configuration options
            columns = { "icon" },                    -- Show file icons
            keymaps = {
                ["q"] = "actions.close",             -- Close the Oil buffer
                ["<CR>"] = "actions.select",         -- Open the selected file/directory
                ["<C-v>"] = "actions.select_vsplit", -- Open in vertical split
                ["<C-s>"] = "actions.select_split",  -- Open in horizontal split
                ["<C-t>"] = "actions.select_tab",    -- Open in a new tab
                ["<C-r>"] = "actions.refresh",       -- Refresh the Oil buffer
            },
            view_options = {
                show_hidden = true, -- Show hidden files
        },
    })

    -- Keybinding
    vim.keymap.set("n", "<leader>e", ":Oil<CR>", { desc = "Open Oil file browser" })
end
