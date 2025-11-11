-- Neoscroll - smooth scrolling
do
    require("neoscroll").setup({
        -- Default keymaps for smooth scrolling
        mappings = {"<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb"},

        -- Hide cursor while scrolling
        hide_cursor = true,

        -- Stop at end of file
        stop_eof = true,

        -- Don't respect scrolloff setting
        respect_scrolloff = false,

        -- Cursor scrolls alone, screen follows
        cursor_scrolls_alone = true,

        -- Easing function for animation (options: sine, circular, quadratic, cubic, quartic)
        easing_function = "sine",

        -- Hooks (nil = no custom hooks)
        pre_hook = nil,
        post_hook = nil,

        -- Performance mode (disables some visual features)
        performance_mode = false,
    })
end
