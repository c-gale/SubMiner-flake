{
  description = "SubMiner - MPV sentence mining overlay";

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bun2nix.url = "github:nix-community/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, bun2nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      bun2nixPkg = bun2nix.packages.${system}.default;

      src = pkgs.fetchgit {
        url = "https://github.com/ksyasuda/SubMiner";
        rev = "d199376364ce799b455fb7d4e852e3e2ffb7f958";
        fetchSubmodules = true;
        hash = "sha256-bqk+zTYi+rn785EBF3R1IetWgurAE/sQGWBA7ZVKjOQ=";
      };

      electronDist = pkgs.fetchurl {
        url = "https://github.com/electron/electron/releases/download/v42.2.0/electron-v42.2.0-linux-x64.zip";
        hash = "sha256-nK7rFdraN8s6LYC/D1iZ0XXbAmpN7xFWCJC9LxloSQk=";      
      };

      subminerYomitan = pkgs.fetchgit {
        url = "https://github.com/ksyasuda/subminer-yomitan";
        rev = "99d6bf853ccf94f10114df5834d5abc68bc8ab55";
        hash = "sha256-6w1ylCO/3LoF5a53s1Fr9t7/OodCQhxBfhpPES2eAEc=";
      };

      texthookerUi = pkgs.fetchgit {
        url = "https://github.com/ksyasuda/texthooker-ui";
        rev = "a40571007099838b498a9db58acabbdb5f1f7071";
        hash = "sha256-+EUe00ZRSJB/YZGOT8vADGF4y1/yL1E3WTz8Zk5yObg=";
      };

      yomitanJlptVocab = pkgs.fetchgit {
        url = "https://github.com/stephenmk/yomitan-jlpt-vocab";
        rev = "b062d4e38c4bdd0950ae1d4ec55f04b176182e03";
        hash = "sha256-5wtEm1YDFJyodAC5k950hJShQRx7yT26fWJancJRXFM=";
      };

      makeBunDeps = { name, cloneUrl, rev, subdir ? null, extraBuildPhase ? "" }: 
        pkgs.stdenvNoCC.mkDerivation {
          inherit name;
          dontUnpack = true;
          dontFixup = true;
          nativeBuildInputs = [ pkgs.bun pkgs.git pkgs.cacert ];
          outputHash = ""; # fill in per-derivation
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          buildPhase = ''
            export HOME=$TMPDIR
            export SOURCE_DATE_EPOCH=1
            export GIT_SSL_CAINFO="$SSL_CERT_FILE"
            git clone ${cloneUrl} repo
            git -C repo checkout ${rev}
            rm -rf repo/.git
            ${extraBuildPhase}
            bun install --no-save --ignore-scripts --cwd repo${if subdir != null then "/${subdir}" else ""}
          '';
          installPhase = ''
            cp -r repo${if subdir != null then "/${subdir}" else ""}/node_modules $out
          '';
        };

      subminerYomitanDeps = pkgs.stdenvNoCC.mkDerivation {
        name = "subminer-yomitan-deps";
        dontUnpack = true;
        dontFixup = true;
        nativeBuildInputs = [ pkgs.bun pkgs.git pkgs.cacert ];
        outputHash = "sha256-F6m0aDB622N+g4tbU15sj7OkawpQnk/bRe3bJecIHKk=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        buildPhase = ''
          export HOME=$TMPDIR
          export SOURCE_DATE_EPOCH=1
          export GIT_SSL_CAINFO="$SSL_CERT_FILE"

          git clone https://github.com/ksyasuda/subminer-yomitan.git repo
          git -C repo checkout 99d6bf853ccf94f10114df5834d5abc68bc8ab55
          rm -rf repo/.git

          # Remove git dep from lockfile — we place it manually below
          sed -i '/"yomitan-handlebars":/d' repo/bun.lock

          bun install --no-save --ignore-scripts --cwd repo

          git clone https://github.com/yomidevs/yomitan-handlebars.git repo/node_modules/@kbn/handlebars
          git -C repo/node_modules/@kbn/handlebars checkout 12aff5e3550954d7d3a98a5917ff7d579f3cce25
          rm -rf repo/node_modules/@kbn/handlebars/.git
        '';
        installPhase = ''
          cp -r repo/node_modules $out
        '';
      };

      texthookerUiDeps = pkgs.stdenvNoCC.mkDerivation {
        name = "subminer-texthooker-ui-deps";
        dontUnpack = true;
        dontFixup = true;
        nativeBuildInputs = [ pkgs.bun pkgs.git pkgs.cacert ];
        outputHash = "sha256-ooy5FPMNIXodvG82j3wbT1hYBr+V2tdIbi/Z0w6R6do=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        buildPhase = ''
          export HOME=$TMPDIR
          export SOURCE_DATE_EPOCH=1
          export GIT_SSL_CAINFO="$SSL_CERT_FILE"

          git clone https://github.com/ksyasuda/texthooker-ui.git repo
          git -C repo checkout a40571007099838b498a9db58acabbdb5f1f7071
          rm -rf repo/.git

          bun install --frozen-lockfile --ignore-scripts --cwd repo
        '';
        installPhase = ''
          cp -r repo/node_modules $out
        '';
      };

      statsDeps = pkgs.stdenvNoCC.mkDerivation {
        name = "subminer-stats-deps";
        dontUnpack = true;
        dontFixup = true;
        nativeBuildInputs = [ pkgs.bun pkgs.git pkgs.cacert ];
        outputHash = "sha256-+HoTfOWeeesCKe/lpq3cmC+EkPXQ0/A8uVZMEBRFBC8=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        buildPhase = ''
          export HOME=$TMPDIR
          export SOURCE_DATE_EPOCH=1
          export GIT_SSL_CAINFO="$SSL_CERT_FILE"

          git clone https://github.com/ksyasuda/SubMiner.git repo
          git -C repo checkout d199376364ce799b455fb7d4e852e3e2ffb7f958

          bun install --frozen-lockfile --ignore-scripts --cwd repo/stats
        '';
        installPhase = ''
          cp -r repo/stats/node_modules $out
        '';
      };

      bunDeps = bun2nixPkg.fetchBunDeps {
        name = "subminer-root-deps";
        src = src;
        bunNix = ./bun.nix;
      };

    in {
      packages.${system}.default = bun2nixPkg.mkDerivation {
        pname = "subminer";
        version = "0.17.0";
        inherit src;

        nativeBuildInputs = with pkgs; [
          bun
          gnumake
          electron_42
          python3
          makeWrapper
          unzip
          git
          nodejs           
          which
        ];

        inherit bunDeps;

        preBuild = ''

          rm -rf vendor/subminer-yomitan
          cp -r ${subminerYomitan} vendor/subminer-yomitan
          chmod -R u+w vendor/subminer-yomitan

          rm -rf vendor/texthooker-ui
          cp -r ${texthookerUi} vendor/texthooker-ui
          chmod -R u+w vendor/texthooker-ui

          rm -rf vendor/yomitan-jlpt-vocab
          cp -r ${yomitanJlptVocab} vendor/yomitan-jlpt-vocab
          chmod -R u+w vendor/yomitan-jlpt-vocab

          mkdir -p vendor/subminer-yomitan/node_modules
          cp -r ${subminerYomitanDeps}/. vendor/subminer-yomitan/node_modules/
          chmod -R u+w vendor/subminer-yomitan/node_modules

          mkdir -p vendor/texthooker-ui/node_modules
          cp -r ${texthookerUiDeps}/. vendor/texthooker-ui/node_modules/
          chmod -R u+w vendor/texthooker-ui/node_modules

          mkdir -p stats/node_modules
          cp -r ${statsDeps}/. stats/node_modules/
          chmod -R u+w stats/node_modules

          NODE=$(which node)
          BUN=$(which bun)
          for dir in stats/node_modules/.bin vendor/subminer-yomitan/node_modules/.bin vendor/texthooker-ui/node_modules/.bin; do
            find "$dir" -maxdepth 1 | while read f; do
              real=$(realpath "$f" 2>/dev/null || readlink -f "$f")
              [ -f "$real" ] || continue
              sed -i "1s|#!/usr/bin/env node|#!$NODE|" "$real"
              sed -i "1s|#!/usr/bin/env bun|#!$BUN|" "$real"
            done
          done          
          sed -i '/git submodule/d' Makefile
          sed -i '/bun install/d' Makefile

          sed -i 's/ensureDependenciesInstalled();//' scripts/build-yomitan.mjs

          mkdir -p $HOME/.cache/electron
          cp ${electronDist} $HOME/.cache/electron/electron-v42.2.0-linux-x64.zip
          echo "$(sha256sum $HOME/.cache/electron/electron-v42.2.0-linux-x64.zip | cut -d' ' -f1)  electron-v42.2.0-linux-x64.zip" \
            > $HOME/.cache/electron/electron-v42.2.0-linux-x64.zip.sha256
        '';

        buildPhase = ''
          runHook preBuild

          export HOME=$TMPDIR
          export SUBMINER_YOMITAN_ALLOW_MISSING_GIT=1

          make deps
          bun run build

          sed -i "s/electron_1\.getVersion()/'0.17.0'/g" dist/main/runtime/update/update-service-runtime.js
          sed -i "s/electron_1\.getVersion()/'0.17.0'/g" dist/main.js
          sed -i "1s/^/const { app } = require('electron'); app.setVersion('0.17.0');\n/" dist/main-entry.js

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/subminer
          cp -r dist/. $out/share/subminer/
          cp -r node_modules $out/share/subminer/node_modules

          cp package.json $out/share/subminer/package.json
          sed -i 's/"version": "0.0"/"version": "0.17.0"/' $out/share/subminer/package.json

          mkdir -p $out/share/build
          cp -r build/yomitan $out/share/build/yomitan

          mkdir -p $out/bin
          makeWrapper ${pkgs.electron_42}/bin/electron $out/bin/subminer \
            --add-flags "--start" \
            --add-flags $out/share/subminer/main-entry.js \
            --set npm_package_version "0.17.0" \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.fzf pkgs.mecab ]}

          mkdir -p $out/share/icons/hicolor/64x64/apps
          cp ${src}/node_modules/.bun/app-builder-lib@26.8.2+ad140fb5a4e95efc/node_modules/app-builder-lib/templates/icons/proton-native/linux/64x64.png $out/share/icons/hicolor/64x64/apps/subminer.png

          mkdir -p $out/share/applications
          cat > $out/share/applications/subminer.desktop << EOF
          [Desktop Entry]
          Name=SubMiner
          Comment=Yomitan-powered sentence mining overlay for MPV
          Exec=$out/bin/subminer --start
          Icon=$out/share/icons/hicolor/64x64/apps/subminer.png
          Type=Application
          Categories=AudioVideo;Education;
          StartupNotify=true
          EOF

          runHook postInstall
        '';  
      };
    };
}
