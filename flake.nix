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
      subminer = pkgs.appimageTools.wrapType2 {
        pname = "subminer";
        version = "0.17.0";
        src = pkgs.fetchurl {
          url = "https://github.com/ksyasuda/SubMiner/releases/download/v0.17.0/SubMiner.AppImage";
          sha256 = "sha256-aEqhxQ0cFxlJ4Tpsh0foIg4O8ZF9QQzVfSULGxPT+iU=";
        };
        extraPkgs = pkgs: with pkgs; [ ];
        extraInstallCommands = ''
          mkdir -p $out/share/applications
          cat > $out/share/applications/subminer.desktop <<EOF
          [Desktop Entry]
          Name=SubMiner
          Exec=subminer
          Icon=subminer
          Type=Application
          Categories=Utility;
          EOF
        '';
      };    
    in {
      packages.default = subminer;

      apps.default = {
        type = "app";
        program = "${subminer}/bin/subminer";
      };
    }
  );
}
