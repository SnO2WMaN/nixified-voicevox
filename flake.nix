{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # dev
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell,
    ...
  } @ inputs: {
    packages."x86_64-linux" = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = with inputs; [
          devshell.overlay
        ];
      };
    in {
      released-core-cpu = pkgs.stdenv.mkDerivation {
        name = "voicevox-core-cpu";
        version = "0.13.0";
        dontBuild = true;

        src = pkgs.fetchzip {
          url = "https://github.com/VOICEVOX/voicevox_core/releases/download/0.13.0/voicevox_core-linux-x64-cpu-0.13.0.zip";
          sha256 = "sha256-/Ikxd3+3/C2Q/qA9RLxxjGSc7ZE2USBO6mJY/d+DC8s=";
        };

        installPhase = ''
          mkdir -p $out
          cp -r $src/core.h $out/core.h
          cp -r $src/libcore.so $out/libcore.so
        '';
      };
      open-jtalk-dict-bin = pkgs.stdenv.mkDerivation {
        name = "open-jtalk-dict-bin";
        version = "1.11";
        dontBuild = true;

        src = builtins.fetchTarball {
          url = "http://downloads.sourceforge.net/open-jtalk/open_jtalk_dic_utf_8-1.11.tar.gz";
          sha256 = "sha256:0ywbimq0xcwnvp9iqi9ivhysr4lizalm2zckds4kj4ydx0m0g9zv";
        };
        installPhase = ''
          mkdir -p $out/open_jtalk_dic_utf_8-1.11
          cp -r $src/* $out/open_jtalk_dic_utf_8-1.11
        '';
      };
      libonnxruntime = pkgs.stdenv.mkDerivation {
        name = "libonnxruntime";
        version = "1.9.0";
        dontBuild = true;

        src = builtins.fetchTarball {
          url = "https://github.com/microsoft/onnxruntime/releases/download/v1.9.0/onnxruntime-linux-x64-1.9.0.tgz";
          sha256 = "sha256:17a5n7knkz24c8wfk1kaabwwpn93wc97f6x43j03ni6dnx046aga";
        };
        installPhase = ''
          mkdir -p $out/lib
          cp -r $src/lib/* $out/lib
        '';
      };
      a = pkgs.linkFarmFromDrvs "a" (with self.packages."x86_64-linux"; [
        released-core-cpu
        open-jtalk-dict-bin
      ]);
      b = pkgs.symlinkJoin {
        name = "b";
        paths =
          (with self.packages."x86_64-linux"; [
            released-core-cpu
            open-jtalk-dict-bin
          ])
          ++ (
            let
              repo = pkgs.fetchFromGitHub {
                owner = "SnO2WMaN";
                repo = "VOICEVOX_CORE";
                rev = "release-0.13";
                sha256 = "sha256-RbB7AFWn7vDcnG1/bHDS5xPAQ9vtgW7UQ07q0lOKCOo=";
              };
            in [
              "${repo}/example/cpp/unix"
              "${repo}/core/src/core.h"
            ]
          );
      };
      example = pkgs.stdenv.mkDerivation (let
        repo = pkgs.fetchFromGitHub {
          owner = "SnO2WMaN";
          repo = "VOICEVOX_CORE";
          rev = "release-0.13";
          sha256 = "sha256-RbB7AFWn7vDcnG1/bHDS5xPAQ9vtgW7UQ07q0lOKCOo=";
        };
      in {
        name = "voicevox-sample";
        version = "0.13";
        src = pkgs.symlinkJoin {
          name = "src";
          paths =
            (with self.packages."x86_64-linux"; [
              released-core-cpu
              open-jtalk-dict-bin
            ])
            ++ (
              let
                repo = pkgs.fetchFromGitHub {
                  owner = "SnO2WMaN";
                  repo = "VOICEVOX_CORE";
                  rev = "release-0.13";
                  sha256 = "sha256-RbB7AFWn7vDcnG1/bHDS5xPAQ9vtgW7UQ07q0lOKCOo=";
                };
              in [
                "${repo}/example/cpp/unix"
                "${repo}/core/src/core.h"
              ]
            );
        };
        # buildInputs = with self.packages."x86_64-linux"; [
        #   released-core-cpu
        #   open-jtalk-dict-bin
        # ];
        buildInputs = with pkgs; [
          cmake
        ];
        buildPhase = with self.packages."x86_64-linux"; ''
          # cp ${released-core-cpu}/libcore.so ./
          # cp -r ${open-jtalk-dict-bin} ./
          cmake -S . -B build
          # cmake --build build
        '';
        installPhase = ''
          ls $build
          mkdir $out
        '';
      });
    };

    devShells."x86_64-linux" = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = with inputs; [
          devshell.overlay
        ];
      };
    in {
      default = pkgs.devshell.mkShell {
        commands = with pkgs; [
          {
            package = "treefmt";
            category = "formatter";
          }
        ];
        packages = with pkgs; [
          cmake
          alejandra
        ];
      };
    };
  };
}
