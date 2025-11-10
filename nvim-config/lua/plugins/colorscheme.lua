-- Melange colorscheme configuration
vim.cmd.colorscheme("melange")

-- Function to toggle background
local function toggle_background()
    if vim.o.background == "dark" then
        vim.o.background = "light"
        scheme = "melange_light"
        print("Switched to light mode")
    else
        vim.o.background = "dark"
        scheme = "melange_dark"
        print("Switched to dark mode")
    end

    local base64_value = vim.fn.system("echo -n " .. vim.fn.shellescape('bar') .. " | base64")
    local escape_seq = string.format("\x1b]1337;SetUserVar=%s=%s\x07", 'wtheme',
        base64_value:match("^%s*(.-)%s*$"))

    vim.fn.system("printf '\\033]1337;SetUserVar=wtheme=%s\\007' $(echo -n 'bar' | base64)")
end

-- Map the function to a key (e.g., <leader>b)
vim.keymap.set('n', '<leader>b', toggle_background,
    { noremap = true, silent = true, desc = "Toggle Background" })

vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })
