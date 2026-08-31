{
  description = "A flake for Wolfram Mathematica";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        installerVersion = "14.3.0";
        installerSource = ./Wolfram_14.3.0_LIN_Bndl.sh;

        mathematicaPackage = pkgs.mathematica.overrideAttrs (oldAttrs: {
          version = installerVersion;
          src = installerSource;
        });

      in {
        packages.default = mathematicaPackage;

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/mathematica";
        };
      }
    );
}
