{
  description = "Quickshell Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell }: let
    targetSystem = "x86_64-linux";
    systemPackages = nixpkgs.legacyPackages.${targetSystem};
    qsPackage = quickshell.packages.${targetSystem}.default;
  in {
    devShells.${targetSystem}.default = systemPackages.mkShell {
      packages = [
        qsPackage
        systemPackages.brightnessctl
        systemPackages.wireplumber
        systemPackages.networkmanager
        systemPackages.bash
      ];

      nativeBuildInputs = [
        systemPackages.qt6.qtdeclarative
        systemPackages.qt6.qtsvg
        systemPackages.qt6.qtimageformats
        systemPackages.qt6.qtmultimedia
        systemPackages.qt6.qt5compat
      ];
    };

    packages.${targetSystem}.default = systemPackages.stdenv.mkDerivation {
      name = "my-quickshell-bar";
      src = ./.;

      nativeBuildInputs = [ 
        systemPackages.qt6.wrapQtAppsHook 
      ];

      buildInputs = [ 
        qsPackage
        systemPackages.qt6.qtsvg
        systemPackages.qt6.qtimageformats
        systemPackages.qt6.qtmultimedia
        systemPackages.qt6.qt5compat
      ];

      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/share/quickshell-bar
        cp -r * $out/share/quickshell-bar

        cat > $out/bin/my-quickshell-bar <<EOF
        #!/bin/sh
        exec ${qsPackage}/bin/quickshell $out/share/quickshell-bar/shell.qml
        EOF
        
        chmod +x $out/bin/my-quickshell-bar
      '';
    };
  };
}
