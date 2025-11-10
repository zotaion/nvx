-- Angular-specific configuration

-- Angular file detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.component.html", "*.component.ts", "*.service.ts", "*.module.ts" },
    callback = function()
        vim.bo.filetype = "typescript"
    end,
})

-- Angular-specific keybindings
local function setup_angular_keymaps()
    -- Navigate between component files
    vim.keymap.set('n', '<leader>ac', function()
        local current_file = vim.fn.expand('%:p')
        local base = current_file:gsub('%.component%.ts$', ''):gsub('%.component%.html$', ''):gsub('%.component%.scss$', ''):gsub('%.component%.css$', '')

        if current_file:match('%.component%.ts$') then
            -- From TypeScript, go to HTML
            vim.cmd('edit ' .. base .. '.component.html')
        elseif current_file:match('%.component%.html$') then
            -- From HTML, go to SCSS/CSS
            if vim.fn.filereadable(base .. '.component.scss') == 1 then
                vim.cmd('edit ' .. base .. '.component.scss')
            elseif vim.fn.filereadable(base .. '.component.css') == 1 then
                vim.cmd('edit ' .. base .. '.component.css')
            else
                vim.cmd('edit ' .. base .. '.component.ts')
            end
        else
            -- From styles, go back to TypeScript
            vim.cmd('edit ' .. base .. '.component.ts')
        end
    end, { desc = "[A]ngular [C]ycle component files" })

    -- Open component template
    vim.keymap.set('n', '<leader>at', function()
        local current_file = vim.fn.expand('%:p')
        local base = current_file:gsub('%.component%.ts$', '')
        vim.cmd('edit ' .. base .. '.component.html')
    end, { desc = "[A]ngular [T]emplate (HTML)" })

    -- Open component styles
    vim.keymap.set('n', '<leader>as', function()
        local current_file = vim.fn.expand('%:p')
        local base = current_file:gsub('%.component%.ts$', '')
        if vim.fn.filereadable(base .. '.component.scss') == 1 then
            vim.cmd('edit ' .. base .. '.component.scss')
        elseif vim.fn.filereadable(base .. '.component.css') == 1 then
            vim.cmd('edit ' .. base .. '.component.css')
        else
            print("No styles file found")
        end
    end, { desc = "[A]ngular [S]tyles (CSS/SCSS)" })

    -- Open component TypeScript
    vim.keymap.set('n', '<leader>aT', function()
        local current_file = vim.fn.expand('%:p')
        local base = current_file:gsub('%.component%.html$', ''):gsub('%.component%.scss$', ''):gsub('%.component%.css$', '')
        vim.cmd('edit ' .. base .. '.component.ts')
    end, { desc = "[A]ngular [T]ypeScript" })
end

-- Setup keymaps for Angular projects
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "html" },
    callback = function()
        -- Check if we're in an Angular project
        local angular_json = vim.fn.findfile('angular.json', '.;')
        if angular_json ~= '' then
            setup_angular_keymaps()
        end
    end,
})

-- Angular snippets helpers
vim.api.nvim_create_user_command('NgComponent', function(opts)
    local name = opts.args
    if name == '' then
        print("Usage: NgComponent <component-name>")
        return
    end

    -- Run ng generate component
    local cmd = 'ng generate component ' .. name
    vim.fn.system(cmd)
    print("Generated component: " .. name)
end, { nargs = 1 })

vim.api.nvim_create_user_command('NgService', function(opts)
    local name = opts.args
    if name == '' then
        print("Usage: NgService <service-name>")
        return
    end

    -- Run ng generate service
    local cmd = 'ng generate service ' .. name
    vim.fn.system(cmd)
    print("Generated service: " .. name)
end, { nargs = 1 })

vim.api.nvim_create_user_command('NgModule', function(opts)
    local name = opts.args
    if name == '' then
        print("Usage: NgModule <module-name>")
        return
    end

    -- Run ng generate module
    local cmd = 'ng generate module ' .. name
    vim.fn.system(cmd)
    print("Generated module: " .. name)
end, { nargs = 1 })
