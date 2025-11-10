-- Spring Boot configuration
do
        -- gain acces to the springboot nvim plugin and its functions
        local springboot_ok, springboot_nvim = pcall(require, "springboot-nvim")
        if not springboot_ok then
            return
        end

        -- set a vim motion to <Space> + <Shift>J + r to run the spring boot project in a vim terminal
        vim.keymap.set('n', '<leader>Jr', function()
            pcall(springboot_nvim.boot_run)
        end, {desc = "[J]ava [R]un Spring Boot"})
        -- set a vim motion to <Space> + <Shift>J + c to open the generate class ui to create a class
        vim.keymap.set('n', '<leader>Jc', function()
            pcall(springboot_nvim.generate_class)
        end, {desc = "[J]ava Create [C]lass"})
        -- set a vim motion to <Space> + <Shift>J + i to open the generate interface ui to create an interface
        vim.keymap.set('n', '<leader>Ji', function()
            pcall(springboot_nvim.generate_interface)
        end, {desc = "[J]ava Create [I]nterface"})
        -- set a vim motion to <Space> + <Shift>J + e to open the generate enum ui to create an enum
        vim.keymap.set('n', '<leader>Je', function()
            pcall(springboot_nvim.generate_enum)
        end, {desc = "[J]ava Create [E]num"})

    -- run the setup function with default configuration
    -- Only setup keymaps for Spring Boot projects
    springboot_nvim.setup({
        -- Disable auto-detection on file open to prevent errors on non-Spring Boot files
        jdtls_name = "jdtls"
    })
end
