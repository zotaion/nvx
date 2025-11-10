{
  description = "nvx - Custom Neovim Configuration with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Package missing plugins
        opencode-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "opencode.nvim";
          version = "2024-11-10";
          src = pkgs.fetchFromGitHub {
            owner = "NickvanDyke";
            repo = "opencode.nvim";
            rev = "8ac5bdf8731a13c19d0876a46b724404e5047f30";
            sha256 = "sha256-s4vskTpQ0hhG57hXoZMjsgpNank79GdMnPJpjnLrIDk=";
          };
        };

        springboot-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "springboot-nvim";
          version = "2024-11-10";
          src = pkgs.fetchFromGitHub {
            owner = "elmcgill";
            repo = "springboot-nvim";
            rev = "3e81c0ed2ca8c05d2cfcbab04addfaa3792dbcb0";
            sha256 = "sha256-Eo67oYzMDgm7dh53LkpeooHm6psIUGNxGul2K3Sjpss=";
          };
          # Skip require check due to module structure
          doCheck = false;
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

        snacks-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "snacks.nvim";
          version = "2024-11-10";
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "snacks.nvim";
            rev = "4e23c75b82aabdb189def39c2c7d2dc25dd0e8a8";
            sha256 = "sha256-s4vskTpQ0hhG57hXoZMjsgpNank79GdMnPJpjnLrIDk=";
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
          lualine-nvim
          which-key-nvim

          # Editing
          comment-nvim
          nvim-autopairs
          vim-surround
          smart-splits-nvim

          # Java/Spring Boot
          springboot-nvim

          # AI
          opencode-nvim
          snacks-nvim

          # Extra
          gen-nvim
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
          pkgs.zls
          # Note: Angular language server is typically installed per-project via npm
          # Install it globally with: npm install -g @angular/language-server
          # Or add it to your project's package.json devDependencies
        ];

        formatters = [
          pkgs.stylua
          pkgs.google-java-format
          pkgs.nodePackages.prettier
          pkgs.python311Packages.autopep8
          pkgs.clang-tools  # clang-format
        ];

        angularTools = [
          pkgs.nodejs  # Required for Angular development and npm
          # Note: Angular CLI and language server are best installed per-project
          # Global install: npm install -g @angular/cli @angular/language-server
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
              --prefix PATH : ${pkgs.lib.makeBinPath (lspServers ++ formatters ++ tools ++ angularTools)} \
              --set JDTLS_PATH "${pkgs.jdt-language-server}"
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
          buildInputs = [ nvx ] ++ lspServers ++ formatters ++ tools ++ angularTools;
        };
      }
    );
}
