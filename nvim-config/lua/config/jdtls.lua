local function get_jdtls()
    -- Get JDTLS path from environment (set by Nix wrapper)
    local jdtls_path = vim.fn.getenv("JDTLS_PATH")

    -- If JDTLS_PATH is not set, try to find jdtls in PATH
    if jdtls_path == vim.NIL or jdtls_path == "" then
        -- Fallback to Mason for compatibility
        local mason_ok, mason_registry = pcall(require, "mason-registry")
        if mason_ok and mason_registry.is_installed("jdtls") then
            local jdtls_pkg = mason_registry.get_package("jdtls")
            jdtls_path = jdtls_pkg:get_install_path()
        else
            -- Try to find in system path
            jdtls_path = vim.fn.system("which jdtls"):gsub("/bin/jdtls", ""):gsub("\n", "")
        end
    end

    -- Obtain the path to the jar which runs the language server
    -- Try Nix structure first (/share/java/jdtls/plugins/), then Mason structure
    local launcher = vim.fn.glob(jdtls_path .. "/share/java/jdtls/plugins/org.eclipse.equinox.launcher_*.jar")
    if launcher == "" then
        launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
    end
    if launcher == "" then
        launcher = vim.fn.glob(jdtls_path .. "/share/java/plugins/org.eclipse.equinox.launcher_*.jar")
    end

    -- Declare which operating system we are using, windows use win, macos use mac
    local SYSTEM = "linux"

    -- Obtain the path to configuration files for your specific operating system
    -- Try Nix structure first (/share/java/jdtls/config_linux), then Mason structure
    local config_source = jdtls_path .. "/share/java/jdtls/config_" .. SYSTEM
    if vim.fn.isdirectory(config_source) == 0 then
        config_source = jdtls_path .. "/config_" .. SYSTEM
    end
    if vim.fn.isdirectory(config_source) == 0 then
        config_source = jdtls_path .. "/share/config_" .. SYSTEM
    end

    -- JDTLS needs to write to the config directory (for native libs, logs, etc.)
    -- Since Nix store is read-only, we need to copy config to a writable location
    local cache_dir = vim.fn.stdpath("cache") .. "/jdtls"
    local config = cache_dir .. "/config_" .. SYSTEM

    -- Copy config to writable location if config.ini doesn't exist
    if vim.fn.filereadable(config .. "/config.ini") == 0 then
        -- Remove old incomplete copy if it exists
        vim.fn.system(string.format("rm -rf '%s'", config))
        -- Ensure parent directory exists
        vim.fn.mkdir(cache_dir, "p")
        -- Copy directory contents (using shell expansion to handle all files including hidden)
        vim.fn.system(string.format("sh -c 'cp -rL \"%s\"/* \"%s\"/  2>/dev/null || true'", config_source, config))
        -- Also copy hidden files if any
        vim.fn.system(string.format("sh -c 'cp -rL \"%s\"/.[!.]* \"%s\"/ 2>/dev/null || true'", config_source, config))
        -- Make writable
        vim.fn.system(string.format("chmod -R u+w '%s' 2>/dev/null || true", config))
    end

    -- Obtain the path to the Lombok jar (optional - Nix JDTLS doesn't include it)
    local lombok = jdtls_path .. "/share/java/jdtls/lombok.jar"
    if vim.fn.filereadable(lombok) == 0 then
        lombok = jdtls_path .. "/lombok.jar"
    end
    if vim.fn.filereadable(lombok) == 0 then
        lombok = jdtls_path .. "/share/lombok.jar"
    end

    return launcher, config, lombok
end

local function get_bundles()
    local bundles = {}

    -- Try to use Mason if available, otherwise skip bundles (Nix might provide them differently)
    local mason_ok, mason_registry = pcall(require, "mason-registry")
    if mason_ok then
        if mason_registry.is_installed("java-debug-adapter") then
            local java_debug = mason_registry.get_package("java-debug-adapter")
            local java_debug_path = java_debug:get_install_path()
            table.insert(bundles, vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1))
        end

        if mason_registry.is_installed("java-test") then
            local java_test = mason_registry.get_package("java-test")
            local java_test_path = java_test:get_install_path()
            vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", 1), "\n"))
        end
    end

    return bundles
end

local function get_workspace()
    -- Get the home directory of your operating system
    local home = os.getenv "HOME"
    -- Declare a directory where you would like to store project information
    local workspace_path = home .. "/code/workspace/"
    -- Determine the project name
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    -- Create the workspace directory by concatenating the designated workspace path and the project name
    local workspace_dir = workspace_path .. project_name
    return workspace_dir
end

local function java_keymaps()
    -- Allow yourself to run JdtCompile as a Vim command
    vim.cmd(
        "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)")
    -- Allow yourself/register to run JdtUpdateConfig as a Vim command
    vim.cmd("command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()")
    -- Allow yourself/register to run JdtBytecode as a Vim command
    vim.cmd("command! -buffer JdtBytecode lua require('jdtls').javap()")
    -- Allow yourself/register to run JdtShell as a Vim command
    vim.cmd("command! -buffer JdtJshell lua require('jdtls').jshell()")

    -- Set a Vim motion to <Space> + <Shift>J + o to organize imports in normal mode
    vim.keymap.set('n', '<leader>Jo', "<Cmd> lua require('jdtls').organize_imports()<CR>",
        { desc = "[J]ava [O]rganize Imports" })
    -- Set a Vim motion to <Space> + <Shift>J + v to extract the code under the cursor to a variable
    vim.keymap.set('n', '<leader>Jv', "<Cmd> lua require('jdtls').extract_variable()<CR>",
        { desc = "[J]ava Extract [V]ariable" })
    -- Set a Vim motion to <Space> + <Shift>J + v to extract the code selected in visual mode to a variable
    vim.keymap.set('v', '<leader>Jv', "<Esc><Cmd> lua require('jdtls').extract_variable(true)<CR>",
        { desc = "[J]ava Extract [V]ariable" })
    -- Set a Vim motion to <Space> + <Shift>J + <Shift>C to extract the code under the cursor to a static variable
    vim.keymap.set('n', '<leader>JC', "<Cmd> lua require('jdtls').extract_constant()<CR>",
        { desc = "[J]ava Extract [C]onstant" })
    -- Set a Vim motion to <Space> + <Shift>J + <Shift>C to extract the code selected in visual mode to a static variable
    vim.keymap.set('v', '<leader>JC', "<Esc><Cmd> lua require('jdtls').extract_constant(true)<CR>",
        { desc = "[J]ava Extract [C]onstant" })
    -- Set a Vim motion to <Space> + <Shift>J + t to run the test method currently under the cursor
    vim.keymap.set('n', '<leader>Jt', "<Cmd> lua require('jdtls').test_nearest_method()<CR>",
        { desc = "[J]ava [T]est Method" })
    -- Set a Vim motion to <Space> + <Shift>J + t to run the test method that is currently selected in visual mode
    vim.keymap.set('v', '<leader>Jt', "<Esc><Cmd> lua require('jdtls').test_nearest_method(true)<CR>",
        { desc = "[J]ava [T]est Method" })
    -- Set a Vim motion to <Space> + <Shift>J + <Shift>T to run an entire test suite (class)
    vim.keymap.set('n', '<leader>JT', "<Cmd> lua require('jdtls').test_class()<CR>", { desc = "[J]ava [T]est Class" })
    -- Set a Vim motion to <Space> + <Shift>J + u to update the project configuration
    vim.keymap.set('n', '<leader>Ju', "<Cmd> JdtUpdateConfig<CR>", { desc = "[J]ava [U]pdate Config" })
end

local function setup_jdtls()
    -- Get access to the jdtls plugin and all of its functionality
    local jdtls = require "jdtls"

    -- Get the paths to the jdtls jar, operating specific configuration directory, and lombok jar
    local launcher, os_config, lombok = get_jdtls()

    -- Get the path you specified to hold project information
    local workspace_dir = get_workspace()

    -- Get the bundles list with the jars to the debug adapter, and testing adapters
    local bundles = get_bundles()

    -- Determine the root directory of the project by looking for these specific markers
    local root_dir = jdtls.setup.find_root({ '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' });

    -- Tell our JDTLS language features it is capable of
    local capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                snippetSupport = false
            }
        }
    }

    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    -- Add general capabilities offset encoding
    lsp_capabilities.general = lsp_capabilities.general or {}
    lsp_capabilities.general.positionEncodings = { "utf-16", "utf-8" }

    for k, v in pairs(lsp_capabilities) do capabilities[k] = v end

    -- Get the default extended client capablities of the JDTLS language server
    local extendedClientCapabilities = jdtls.extendedClientCapabilities
    -- Modify one property called resolveAdditionalTextEditsSupport and set it to true
    extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

    -- Set the command that starts the JDTLS language server jar
    local cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xms1g',                  -- Initial heap size
        '-Xmx4g',                  -- Maximum heap size (change this!)
        '-XX:+UseG1GC',            -- Better garbage collector
        '-XX:+UseStringDeduplication', -- Reduces memory usage
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    }

    -- Add Lombok javaagent if it exists
    if vim.fn.filereadable(lombok) == 1 then
        table.insert(cmd, '-javaagent:' .. lombok)
    end

    -- Add remaining command arguments
    vim.list_extend(cmd, {
        '-jar',
        launcher,
        '-configuration',
        os_config,
        '-data',
        workspace_dir,
        '-clean',
    })

    -- Configure settings in the JDTLS server
    local settings = {
        init_options = {
            bundles = {},
            workspaceFolders = true
        },
        java = {
            -- Enable all compiler options
            compilerOptions = {
                enablePreviewFeatures = true,
                -- Add MapStruct compiler arguments
                generatedOutputDirectory = "target/generated-sources/annotations"
            },
            cleanup = {
                actionsOnStart = {
                    "cleanup",
                    "organize"
                }
            },
            autobuild = {
                enabled = true,
            },
            -- Enable code formatting
            format = {
                enabled = true,
                -- Use the Google Style guide for code formattingh
                settings = {
                    -- url = vim.fn.stdpath("config") .. "/lang_servers/intellij-java-google-style.xml",
                    -- profile = "GoogleStyle"
                    url = "/home/ion/.config/nvim/lang_servers/intellij-java-google-style.xml",
                }
            },
            -- Enable downloading archives from eclipse automatically
            eclipse = {
                downloadSource = true
            },
            -- Enable downloading archives from maven automatically
            maven = {
                downloadSources = true
            },
            -- Enable method signature help
            signatureHelp = {
                enabled = true
            },
            -- Use the fernflower decompiler when using the javap command to decompile byte code back to java code
            contentProvider = {
                preferred = "fernflower"
            },
            -- Setup automatical package import oranization on file save
            saveActions = {
                organizeImports = true
            },
            -- Customize completion options
            completion = {
                -- When using an unimported static method, how should the LSP rank possible places to import the static method from
                favoriteStaticMembers = {
                    "org.hamcrest.MatcherAssert.assertThat",
                    "org.hamcrest.Matchers.*",
                    "org.hamcrest.CoreMatchers.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                    "org.mockito.Mockito.*",
                },
                -- Try not to suggest imports from these packages in the code action window
                filteredTypes = {
                    "com.sun.*",
                    "io.micrometer.shaded.*",
                    "java.awt.*",
                    "jdk.*",
                    "sun.*",
                },
                -- Set the order in which the language server should organize imports
                importOrder = {
                    "java",
                    "jakarta",
                    "javax",
                    "lombok",
                    "ro",
                    "com",
                    "org.springframework"
                }
            },
            sources = {
                -- How many classes from a specific package should be imported before automatic imports combine them all into a single import
                organizeImports = {
                    starThreshold = 9999,
                    staticThreshold = 9999
                }
            },
            -- How should different pieces of code be generated?
            codeGeneration = {
                -- When generating toString use a json format
                toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
                },
                -- When generating hashCode and equals methods use the java 7 objects method
                hashCodeEquals = {
                    useJava7Objects = true
                },
                -- When generating code use code blocks
                useBlocks = true
            },
            -- If changes to the project will require the developer to update the projects configuration advise the developer before accepting the change
            configuration = {
                updateBuildConfiguration = "interactive",
                annotationProcessing = {
                    enabled = true, -- Enable annotation processing
                },
            },
            -- enable code lens in the lsp
            referencesCodeLens = {
                enabled = true
            },
            -- enable inlay hints for parameter names,
            inlayHints = {
                parameterNames = {
                    enabled = "all"
                }
            }
        }
    }

    -- Create a table called init_options to pass the bundles with debug and testing jar, along with the extended client capablies to the start or attach function of JDTLS
    local init_options = {
        bundles = bundles,
        extendedClientCapabilities = extendedClientCapabilities
    }

    -- Function that will be ran once the language server is attached
    local on_attach = function(_, bufnr)
        -- Map the Java specific key mappings once the server is attached
        java_keymaps()

        -- Setup the java debug adapter of the JDTLS server
        require('jdtls.dap').setup_dap()

        -- Find the main method(s) of the application so the debug adapter can successfully start up the application
        -- Sometimes this will randomly fail if language server takes to long to startup for the project, if a ClassDefNotFoundException occurs when running
        -- the debug tool, attempt to run the debug tool while in the main class of the application, or restart the neovim instance
        -- Unfortunately I have not found an elegant way to ensure this works 100%
        require('jdtls.dap').setup_dap_main_class_configs()
        -- Enable jdtls commands to be used in Neovim
        require 'jdtls.setup'.add_commands()
        -- Refresh the codelens
        -- Code lens enables features such as code reference counts, implemenation counts, and more.
        vim.lsp.codelens.refresh()

        require("lsp_signature").on_attach({
            bind = true,
            padding = "",
            handler_opts = {
                border = "rounded",
            },
            hint_prefix = "󱄑 ",
        }, bufnr)

        -- Setup a function that automatically runs every time a java file is saved to refresh the code lens
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.java" },
            callback = function()
                local _, _ = pcall(vim.lsp.codelens.refresh)
                vim.lsp.buf.execute_command({
                    command = "java.project.refreshDiagnostics",
                    arguments = { "full" }
                })
            end
        })
    end

    -- Create the configuration table for the start or attach function
    local config = {
        cmd = cmd,
        root_dir = root_dir,
        settings = settings,
        capabilities = capabilities,
        init_options = init_options,
        on_attach = on_attach
    }

    -- Start the JDTLS server
    require('jdtls').start_or_attach(config)
end

return {
    setup_jdtls = setup_jdtls,
}
