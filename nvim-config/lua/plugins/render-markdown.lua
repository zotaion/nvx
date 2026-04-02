-- Render Markdown configuration
do
    require("render-markdown").setup({
        -- Disable latex support (no latex tools installed)
        latex = { enabled = false },
    })
end
