{
  description = "nvx - Custom Neovim Configuration with Nix";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Package missing plugins
        # Build lualine-nvim directly to avoid rockspec hash mismatch
        lualine-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "lualine.nvim";
          version = "2024-11-26";
          src = pkgs.fetchFromGitHub {
            owner = "nvim-lualine";
            repo = "lualine.nvim";
            rev = "0a5a66803c7407767b799067986b4dc3036e1983";
            sha256 = "sha256-WcH2dWdRDgMkwBQhcgT+Z/ArMdm+VbRhmQftx4t2kNI=";
          };
        };

        gen-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "gen.nvim";
          version = "2024-11-10";
          src = pkgs.fetchFromGitHub {
            owner = "David-Kunz";
            repo = "gen.nvim";
            rev = "c8e1f574d4a3a839dde73a87bdc319a62ee1e559";
            sha256 = "sha256-s12r8dvva0O2VvEPjOQvpjVpEehxsa4AWoGHXFYxQlI=";
          };
        };

        # Build telescope-fzf-native with make
        telescope-fzf-native = pkgs.vimPlugins.telescope-fzf-native-nvim.overrideAttrs (old: {
          buildPhase = ''
            make
          '';
          nativeBuildInputs = [ pkgs.gnumake pkgs.gcc ];
        });

        # All plugins
        plugins = with pkgs.vimPlugins; [
          # Core infrastructure
          plenary-nvim
          nvim-web-devicons

          # LSP & Language Support
          mason-nvim
          mason-lspconfig-nvim
          mason-nvim-dap-nvim
          nvim-lspconfig
          nvim-jdtls
          lsp_signature-nvim

          # Syntax (with all grammars)
          (nvim-treesitter.withAllGrammars)
          nvim-ts-autotag
          nvim-ts-context-commentstring

          # Completion
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          luasnip
          cmp_luasnip
          friendly-snippets
          supermaven-nvim

          # Debugging
          nvim-dap
          nvim-dap-ui
          nvim-nio

          # Formatting
          conform-nvim

          # Navigation
          telescope-nvim
          telescope-fzf-native
          telescope-ui-select-nvim
          harpoon
          flash-nvim
          oil-nvim

          # Git
          gitsigns-nvim
          vim-fugitive
          diffview-nvim

          # UI
          melange-nvim
          lualine-nvim  # Using custom override above
          which-key-nvim

          # Editing
          comment-nvim
          nvim-autopairs
          vim-surround
          smart-splits-nvim
          neoscroll-nvim

          # Extra
          gen-nvim
          render-markdown-nvim
        ];

        # Configuration directory
        neovimConfig = pkgs.stdenv.mkDerivation {
          name = "nvx-config";
          src = ./nvim-config;
          installPhase = ''
            mkdir -p $out
            cp -r lua $out/
            cp init.lua $out/
          '';
        };

        # Build package path (must match NVIM_APPNAME/site for XDG_DATA_DIRS)
        packpath = pkgs.runCommandLocal "nvx-packpath" {} ''
          mkdir -p $out/nvx/site/pack/nvx/start
          ${pkgs.lib.concatMapStringsSep "\n" (plugin: ''
            ln -s ${plugin} $out/nvx/site/pack/nvx/start/${plugin.pname or plugin.name}
          '') plugins}
        '';

        # LSP servers and tools
        lspServers = [
          pkgs.lua-language-server
          pkgs.nodePackages.typescript-language-server
          pkgs.jdt-language-server
          pkgs.vscode-langservers-extracted  # cssls, html, eslint, json
          pkgs.zls  # Zig language server
          pkgs.rust-analyzer
          pkgs.nodePackages.svelte-language-server
          # Note: Angular language server is typically installed per-project via npm
          # Install it globally with: npm install -g @angular/language-server
          # Or add it to your project's package.json devDependencies
        ];

        # Java tools
        javaTools = [
          pkgs.lombok  # Lombok agent for jdtls
        ];

        formatters = [
          pkgs.stylua
          pkgs.google-java-format
          pkgs.nodePackages.prettier
          pkgs.python311Packages.autopep8
          pkgs.clang-tools  # clang-format
          pkgs.rustfmt
        ];

        angularTools = [
          pkgs.nodejs  # Required for Angular development and npm
          pkgs.angular-language-server  # Angular language server
        ];

        rustTools = [
          pkgs.cargo
          pkgs.rustc
          pkgs.clippy
        ];

        svelteTools = [
          pkgs.nodejs  # Required for Svelte development and npm
        ];

        tools = [
          pkgs.ripgrep
          pkgs.fd
          pkgs.git
          pkgs.gnumake
          pkgs.gcc
        ];

        # Wrapped neovim
        nvx = pkgs.symlinkJoin {
          name = "nvx";
          paths = [ pkgs.neovim-unwrapped ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/nvim \
              --add-flags "-u ${neovimConfig}/init.lua" \
              --add-flags "--cmd 'set runtimepath^=${neovimConfig}'" \
              --set NVIM_APPNAME "nvx" \
              --prefix XDG_DATA_DIRS : "${packpath}" \
              --prefix PATH : ${pkgs.lib.makeBinPath (lspServers ++ formatters ++ tools ++ angularTools ++ javaTools ++ rustTools ++ svelteTools)} \
              --set JDTLS_PATH "${pkgs.jdt-language-server}" \
              --set LOMBOK_PATH "${pkgs.lombok}/share/java/lombok.jar"
          '';
        };

      in {
        packages = {
          default = nvx;
          nvx = nvx;
        };

        apps = {
          default = {
            type = "app";
            program = "${nvx}/bin/nvim";
          };
          nvx = {
            type = "app";
            program = "${nvx}/bin/nvim";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ nvx ] ++ lspServers ++ formatters ++ tools ++ angularTools ++ javaTools ++ rustTools ++ svelteTools;
        };
      }
    );
}
