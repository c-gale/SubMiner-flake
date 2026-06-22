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
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "subminer";
          version = "0.17.0";

          src = pkgs.fetchurl {
            url = "https://github.com/ksyasuda/SubMiner/releases/download/v0.17.0/SubMiner.AppImage";
            sha256 = "sha256-aEqhxQ0cFxlJ4Tpsh0foIg4O8ZF9QQzVfSULGxPT+iU=";
          };

          nativeBuildInputs = [ pkgs.autoPatchelfHook ];

          buildInputs = [
            pkgs.fuse
            pkgs.zlib
          ];

          dontUnpack = true;
          dontBuild = true;

          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/subminer
            chmod +x $out/bin/subminer
          '';
        };      
      }
    );
}
