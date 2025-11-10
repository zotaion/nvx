-- Harpoon configuration
local function mark_file()
    require("harpoon.mark").add_file()
    vim.notify "󱡅  marked file"
end

-- Set a vim motion to <Shift>m to mark a file with harpoon
vim.keymap.set("n", "<s-m>", mark_file, {desc = "Harpoon Mark File"})
-- Set a vim motion to the tab key to open the harpoon menu to easily navigate frequented files
vim.keymap.set("n", "<TAB>", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", {desc = "Harpoon Toggle Menu"})
