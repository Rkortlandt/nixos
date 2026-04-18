{
  description = "A flake for AdvantageScope (Electron FRC Telemetry App)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Change this to the latest version found on their GitHub releases
        version = "26.0.1"; 
        
        # Map Nix system architecture to AdvantageScope's release naming
        arch = if system == "x86_64-linux" then "x64"
               else if system == "aarch64-linux" then "arm64"
               else throw "Unsupported architecture for AdvantageScope";

        # Fetch the official AppImage
        src = pkgs.fetchurl {
          url = "https://github.com/Mechanical-Advantage/AdvantageScope/releases/download/v${version}/advantagescope-linux-${arch}-v${version}.AppImage";
          hash = "sha256-1HYX/plizbrHhoiV7oIYIvqSmZGRV0Nzk4SRn4PwWoQ=";
        };

        # Extract the AppImage so we can grab the desktop file and icons
        appimageContents = pkgs.appimageTools.extractType2 {
          pname = "advantagescope";
          inherit version src;
        };

      in {
        packages.default = pkgs.appimageTools.wrapType2 {
          pname = "advantagescope";
          inherit version src;

          # Electron apps often require this flag in Wayland environments
          extraPkgs = pkgs: with pkgs; [ ];

          extraInstallCommands = ''
            # Install the desktop entry
            install -m 444 -D ${appimageContents}/advantagescope.desktop -t $out/share/applications
            
            # Fix the Exec line in the desktop file
            substituteInPlace $out/share/applications/advantagescope.desktop \
              --replace-fail 'Exec=AppRun' 'Exec=advantagescope'
              
            # Copy icons so it looks nice in your app launcher
            cp -r ${appimageContents}/usr/share/icons $out/share
          '';
        };
        
        # Allows you to run the app directly via `nix run`
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/advantagescope";
        };
      }
    );
}
