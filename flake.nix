{
  description = "SubMiner nixos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.writeShellScriptBin "subminer" ''
          exec ${pkgs.appimage-run}/bin/appimage-run ${pkgs.fetchurl {
            url = "https://github.com/ksyasuda/SubMiner/releases/download/v0.17.0/SubMiner.AppImage";
            sha256 = "sha256-aEqhxQ0cFxlJ4Tpsh0foIg4O8ZF9QQzVfSULGxPT+iU=";
          }} "$@"
        '';      
        }
    );
}
