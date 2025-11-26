-- Rust-specific configuration

-- Rust file detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.rs" },
	callback = function()
		vim.bo.filetype = "rust"
	end,
})

-- Rust-specific keybindings
local function setup_rust_keymaps()
	-- Run cargo build
	vim.keymap.set("n", "<leader>rb", function()
		vim.cmd("terminal cargo build")
	end, { desc = "[R]ust [B]uild" })

	-- Run cargo run
	vim.keymap.set("n", "<leader>rr", function()
		vim.cmd("terminal cargo run")
	end, { desc = "[R]ust [R]un" })

	-- Run cargo test
	vim.keymap.set("n", "<leader>rt", function()
		vim.cmd("terminal cargo test")
	end, { desc = "[R]ust [T]est" })

	-- Run cargo test for the current module
	vim.keymap.set("n", "<leader>rT", function()
		local current_word = vim.fn.expand("<cword>")
		vim.cmd("terminal cargo test " .. current_word)
	end, { desc = "[R]ust [T]est current" })

	-- Run cargo check
	vim.keymap.set("n", "<leader>rc", function()
		vim.cmd("terminal cargo check")
	end, { desc = "[R]ust [C]heck" })

	-- Run cargo clippy
	vim.keymap.set("n", "<leader>rl", function()
		vim.cmd("terminal cargo clippy")
	end, { desc = "[R]ust C[l]ippy" })

	-- Format with rustfmt
	vim.keymap.set("n", "<leader>rf", function()
		vim.cmd("!rustfmt %")
		vim.cmd("edit")
	end, { desc = "[R]ust [F]ormat" })

	-- Open Cargo.toml
	vim.keymap.set("n", "<leader>rC", function()
		local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
		if cargo_toml ~= "" then
			vim.cmd("edit " .. cargo_toml)
		else
			print("Cargo.toml not found")
		end
	end, { desc = "[R]ust [C]argo.toml" })

	-- Expand macro under cursor (requires rust-analyzer)
	vim.keymap.set("n", "<leader>rm", function()
		vim.lsp.buf.execute_command({
			command = "rust-analyzer.expandMacro",
			arguments = { vim.api.nvim_buf_get_name(0), vim.api.nvim_win_get_cursor(0) },
		})
	end, { desc = "[R]ust Expand [M]acro" })
end

-- Setup keymaps for Rust projects
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "rust" },
	callback = function()
		-- Check if we're in a Rust project (has Cargo.toml)
		local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
		if cargo_toml ~= "" then
			setup_rust_keymaps()
		end
	end,
})

-- Rust commands
vim.api.nvim_create_user_command("RustNew", function(opts)
	local name = opts.args
	if name == "" then
		print("Usage: RustNew <project-name>")
		return
	end

	-- Run cargo new
	local cmd = "cargo new " .. name
	vim.fn.system(cmd)
	print("Created Rust project: " .. name)
end, { nargs = 1 })

vim.api.nvim_create_user_command("RustAddCrate", function(opts)
	local crate = opts.args
	if crate == "" then
		print("Usage: RustAddCrate <crate-name>")
		return
	end

	-- Run cargo add
	local cmd = "cargo add " .. crate
	vim.fn.system(cmd)
	print("Added crate: " .. crate)
end, { nargs = 1 })

vim.api.nvim_create_user_command("RustDoc", function()
	-- Open cargo documentation
	vim.fn.system("cargo doc --open")
	print("Opening Rust documentation...")
end, { nargs = 0 })
