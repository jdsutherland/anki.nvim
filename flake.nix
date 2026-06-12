{
  description = "anki.nvim - Neovim plugin for Anki flashcard management via AnkiConnect";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        anki-nvim = pkgs.stdenv.mkDerivation {
          name = "anki-nvim";
          src = self;
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r lua $out/
            cp -r doc $out/ 2>/dev/null || true
            runHook postInstall
          '';
        };

        neovimWithPlugins = pkgs.neovim.override {
          configure = {
            customRC = ''
              set runtimepath^=${anki-nvim}
              set runtimepath^=${pkgs.vimPlugins.plenary-nvim}
              set runtimepath^=${pkgs.vimPlugins.snacks-nvim}
              lua require('anki').setup()
            '';
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            neovimWithPlugins
            (pkgs.anki.withAddons (with pkgs.ankiAddons; [ anki-connect ]))
            pkgs.vimcats
            pkgs.stylua
          ];
        };
      }
    );
}