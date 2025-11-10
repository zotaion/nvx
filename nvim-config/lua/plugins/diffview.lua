-- Diffview configuration
do
            require("diffview").setup({
                -- Add any Diffview-specific options here
            })

            -- Keybindings for Diffview
            local map = vim.keymap.set
            local opts = { noremap = true, silent = true, desc = "Diffview" }

            map("n", "<leader>gd", ":DiffviewOpen<CR>", vim.tbl_extend("force", opts, { desc = "Open [D]iffview" }))
            map("n", "<leader>gq", ":DiffviewClose<CR>", vim.tbl_extend("force", opts, { desc = "[Q]uit Diffview" }))
        map("n", "<leader>gF", ":DiffviewFileHistory<CR>", vim.tbl_extend("force", opts, { desc = "[F]ile History" }))
end
