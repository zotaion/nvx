-- Svelte/SvelteKit-specific configuration

-- Svelte file detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.svelte" },
	callback = function()
		vim.bo.filetype = "svelte"
	end,
})

-- Svelte-specific keybindings
local function setup_svelte_keymaps()
	-- Run dev server
	vim.keymap.set("n", "<leader>sd", function()
		vim.cmd("terminal npm run dev")
	end, { desc = "[S]velte [D]ev server" })

	-- Build project
	vim.keymap.set("n", "<leader>sb", function()
		vim.cmd("terminal npm run build")
	end, { desc = "[S]velte [B]uild" })

	-- Preview production build
	vim.keymap.set("n", "<leader>sp", function()
		vim.cmd("terminal npm run preview")
	end, { desc = "[S]velte [P]review" })

	-- Run type checking
	vim.keymap.set("n", "<leader>st", function()
		vim.cmd("terminal npm run check")
	end, { desc = "[S]velte [T]ype check" })

	-- Navigate between SvelteKit route files
	vim.keymap.set("n", "<leader>sr", function()
		local current_file = vim.fn.expand("%:p")
		local dir = vim.fn.fnamemodify(current_file, ":h")

		-- Cycle through SvelteKit route files
		if current_file:match("%+page%.svelte$") then
			-- From +page.svelte, go to +page.ts
			if vim.fn.filereadable(dir .. "/+page.ts") == 1 then
				vim.cmd("edit " .. dir .. "/+page.ts")
			elseif vim.fn.filereadable(dir .. "/+page.js") == 1 then
				vim.cmd("edit " .. dir .. "/+page.js")
			elseif vim.fn.filereadable(dir .. "/+page.server.ts") == 1 then
				vim.cmd("edit " .. dir .. "/+page.server.ts")
			end
		elseif current_file:match("%+page%.ts$") or current_file:match("%+page%.js$") then
			-- From +page.ts/js, go to +page.server.ts
			if vim.fn.filereadable(dir .. "/+page.server.ts") == 1 then
				vim.cmd("edit " .. dir .. "/+page.server.ts")
			elseif vim.fn.filereadable(dir .. "/+page.server.js") == 1 then
				vim.cmd("edit " .. dir .. "/+page.server.js")
			elseif vim.fn.filereadable(dir .. "/+layout.svelte") == 1 then
				vim.cmd("edit " .. dir .. "/+layout.svelte")
			else
				vim.cmd("edit " .. dir .. "/+page.svelte")
			end
		elseif current_file:match("%+page%.server%.ts$") or current_file:match("%+page%.server%.js$") then
			-- From +page.server.ts/js, go to +layout.svelte
			if vim.fn.filereadable(dir .. "/+layout.svelte") == 1 then
				vim.cmd("edit " .. dir .. "/+layout.svelte")
			else
				vim.cmd("edit " .. dir .. "/+page.svelte")
			end
		elseif current_file:match("%+layout%.svelte$") then
			-- From +layout.svelte, go to +layout.ts
			if vim.fn.filereadable(dir .. "/+layout.ts") == 1 then
				vim.cmd("edit " .. dir .. "/+layout.ts")
			elseif vim.fn.filereadable(dir .. "/+layout.js") == 1 then
				vim.cmd("edit " .. dir .. "/+layout.js")
			else
				vim.cmd("edit " .. dir .. "/+page.svelte")
			end
		else
			-- Default: go to +page.svelte
			if vim.fn.filereadable(dir .. "/+page.svelte") == 1 then
				vim.cmd("edit " .. dir .. "/+page.svelte")
			end
		end
	end, { desc = "[S]velte [R]oute cycle" })

	-- Open page component
	vim.keymap.set("n", "<leader>sP", function()
		local current_file = vim.fn.expand("%:p")
		local dir = vim.fn.fnamemodify(current_file, ":h")
		if vim.fn.filereadable(dir .. "/+page.svelte") == 1 then
			vim.cmd("edit " .. dir .. "/+page.svelte")
		else
			print("No +page.svelte found")
		end
	end, { desc = "[S]velte [P]age component" })

	-- Open layout component
	vim.keymap.set("n", "<leader>sl", function()
		local current_file = vim.fn.expand("%:p")
		local dir = vim.fn.fnamemodify(current_file, ":h")
		if vim.fn.filereadable(dir .. "/+layout.svelte") == 1 then
			vim.cmd("edit " .. dir .. "/+layout.svelte")
		else
			print("No +layout.svelte found")
		end
	end, { desc = "[S]velte [L]ayout component" })

	-- Open server file
	vim.keymap.set("n", "<leader>sS", function()
		local current_file = vim.fn.expand("%:p")
		local dir = vim.fn.fnamemodify(current_file, ":h")
		if vim.fn.filereadable(dir .. "/+page.server.ts") == 1 then
			vim.cmd("edit " .. dir .. "/+page.server.ts")
		elseif vim.fn.filereadable(dir .. "/+page.server.js") == 1 then
			vim.cmd("edit " .. dir .. "/+page.server.js")
		else
			print("No +page.server.ts/js found")
		end
	end, { desc = "[S]velte [S]erver file" })

	-- Open svelte.config.js
	vim.keymap.set("n", "<leader>sc", function()
		local svelte_config = vim.fn.findfile("svelte.config.js", ".;")
		if svelte_config ~= "" then
			vim.cmd("edit " .. svelte_config)
		else
			print("svelte.config.js not found")
		end
	end, { desc = "[S]velte [C]onfig" })
end

-- Setup keymaps for Svelte projects
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "svelte", "typescript", "javascript" },
	callback = function()
		-- Check if we're in a SvelteKit project
		local svelte_config = vim.fn.findfile("svelte.config.js", ".;")
		local package_json = vim.fn.findfile("package.json", ".;")

		if svelte_config ~= "" or package_json ~= "" then
			-- Check if package.json contains SvelteKit
			if package_json ~= "" then
				local content = vim.fn.readfile(package_json)
				local content_str = table.concat(content, "\n")
				if content_str:match("@sveltejs/kit") or content_str:match('"svelte"') then
					setup_svelte_keymaps()
				end
			elseif svelte_config ~= "" then
				setup_svelte_keymaps()
			end
		end
	end,
})

-- Svelte commands
vim.api.nvim_create_user_command("SvelteNewRoute", function(opts)
	local route = opts.args
	if route == "" then
		print("Usage: SvelteNewRoute <route-path>")
		return
	end

	-- Create route directory and files
	local route_dir = "src/routes/" .. route
	vim.fn.mkdir(route_dir, "p")

	-- Create +page.svelte
	local page_file = route_dir .. "/+page.svelte"
	vim.fn.writefile({
		"<script lang=\"ts\">",
		"</script>",
		"",
		"<div>",
		"\t<h1>New Route</h1>",
		"</div>",
		"",
		"<style>",
		"</style>",
	}, page_file)

	vim.cmd("edit " .. page_file)
	print("Created SvelteKit route: " .. route)
end, { nargs = 1 })

vim.api.nvim_create_user_command("SvelteNewComponent", function(opts)
	local name = opts.args
	if name == "" then
		print("Usage: SvelteNewComponent <ComponentName>")
		return
	end

	-- Create component in lib/components
	local component_dir = "src/lib/components"
	vim.fn.mkdir(component_dir, "p")

	local component_file = component_dir .. "/" .. name .. ".svelte"
	vim.fn.writefile({
		"<script lang=\"ts\">",
		"</script>",
		"",
		"<div>",
		"\t<p>" .. name .. "</p>",
		"</div>",
		"",
		"<style>",
		"</style>",
	}, component_file)

	vim.cmd("edit " .. component_file)
	print("Created Svelte component: " .. name)
end, { nargs = 1 })
