-- LSP configuration (Mason setup kept for compatibility but LSP servers provided by Nix)
do
    -- setup mason with default properties (for manual package management if needed)
    require("mason").setup({
        ui = {
            border = "rounded"
        }
    })

    -- mason lsp config setup (LSP servers provided by Nix PATH)
    require("mason-lspconfig").setup({
        ensure_installed = {},  -- Empty, Nix provides all servers: lua_ls, ts_ls, jdtls, cssls, zls, angularls, html, eslint
        automatic_installation = false,
    })

    -- mason nvim dap setup (debug adapters provided by Nix)
    require("mason-nvim-dap").setup({
        ensure_installed = {},  -- Empty, Nix provides adapters
        automatic_installation = false,
    })

    -- lsp signature setup
    require("lsp_signature").setup()
end

-- nvim-lspconfig setup
do
    local icons = require("config.icons")

    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    -- Add general capabilities offset encoding
    capabilities.general = capabilities.general or {}
    capabilities.general.positionEncodings = { "utf-16", "utf-8" }

    -- Setup LSP servers using vim.lsp.config (new API for Neovim 0.11+)
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    local servers = {
        lua_ls = {},
        ts_ls = {},
        cssls = {},
        zls = {},
        html = {},
        eslint = {},
    }

    -- Setup each server using the proper API
    for server, config in pairs(servers) do
        config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
        lspconfig[server].setup(config)
    end

    -- Angular language server - override on_new_config to fix cmd resolution
    -- The default on_new_config uses vim.fn.exepath() which fails with Nix-provided ngserver
    lspconfig.angularls.setup({
        capabilities = capabilities,
        on_new_config = function(new_config, new_root_dir)
            -- Helper functions from lspconfig
            local function get_probe_dir(root_dir)
                local project_root = vim.fs.dirname(vim.fs.find('node_modules', { path = root_dir, upward = true })[1])
                return project_root and (project_root .. '/node_modules') or ''
            end

            local function get_angular_core_version(root_dir)
                local project_root = vim.fs.dirname(vim.fs.find('node_modules', { path = root_dir, upward = true })[1])
                if not project_root then return '' end

                local package_json = project_root .. '/package.json'
                if not vim.uv.fs_stat(package_json) then return '' end

                local contents = io.open(package_json):read('*a')
                local json = vim.json.decode(contents)
                if not json.dependencies then return '' end

                local angular_core_version = json.dependencies['@angular/core']
                return angular_core_version and angular_core_version:match('%d+%.%d+%.%d+') or ''
            end

            local new_probe_dir = get_probe_dir(new_root_dir)
            local angular_core_version = get_angular_core_version(new_root_dir)

            -- Use 'ngserver' directly instead of vim.fn.exepath() which fails with Nix PATH
            new_config.cmd = {
                'ngserver',  -- Will be found in PATH from Nix wrapper
                '--stdio',
                '--tsProbeLocations',
                new_probe_dir,
                '--ngProbeLocations',
                new_probe_dir,
                '--angularCoreVersion',
                angular_core_version,
            }
        end,
    })


            local default_diagnostic_config = {
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
                        [vim.diagnostic.severity.WARN] = icons.diagnostics.Warning,
                        [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
                        [vim.diagnostic.severity.INFO] = icons.diagnostics.Information,
                    },
                },
                virtual_text = false,
                update_in_insert = false,
                underline = true,
                severity_sort = true,
                float = {
                    focusable = true,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            }

            vim.diagnostic.config(default_diagnostic_config)



            -- Set vim motion for <Space> + c + h to show code documentation about the code the cursor is currently over if available
            vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "[C]ode [H]over Documentation" })
            -- Set vim motion for <Space> + c + d to go where the code/variable under the cursor was defined
            vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "[C]ode Goto [D]efinition" })
            -- Set vim motion for <Space> + c + a for display code action suggestions for code diagnostics in both normal and visual mode
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ctions" })
            -- Set vim motion for <Space> + c + r to display references to the code under the cursor
            vim.keymap.set(
                "n",
                "<leader>cr",
                require("telescope.builtin").lsp_references,
                { desc = "[C]ode Goto [R]eferences" }
            )
            -- Set vim motion for <Space> + c + i to display implementations to the code under the cursor
            vim.keymap.set(
                "n",
                "<leader>ci",
                require("telescope.builtin").lsp_implementations,
                { desc = "[C]ode Goto [I]mplementations" }
            )
            -- Set a vim motion for <Space> + c + <Shift>R to smartly rename the code under the cursor
            vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { desc = "[C]ode [R]ename" })
    -- Set a vim motion for <Space> + c + <Shift>D to go to where the code/object was declared in the project (class file)
    vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "[C]ode Goto [D]eclaration" })
end
