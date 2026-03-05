{
  description = "AdvantageScope - FRC Robot telemetry application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.buildNpmPackage rec {
          pname = "advantagescope";
          version = "26.0.0"; # Update this to the desired version tag (e.g., v26.0.0)

          src = pkgs.fetchFromGitHub {
            owner = "Mechanical-Advantage";
            repo = "AdvantageScope";
            rev = "v${version}";
            # Replace this hash with the actual output hash after your first build attempt
            hash = "sha256-ZkA7u/QlM5+w4l6ZrlRAxhtPelyLi4LqSjGs27IFGKU=";
          };

          # Replace this hash with the actual npm dependency hash after your first build attempt
          npmDepsHash = "sha256-Nvo31MS6sMonxxpqIN3IyLsJRjnt/deTfT7lOv7fGCQ=";
          forceGitDeps = true;
          makeCacheWritable = true;

          nativeBuildInputs = with pkgs; [
            python3
            pkg-config
            makeWrapper
            emscripten
            nodePackages.node-gyp
            # Required for Wayland / Linux build processes
            electron
          ];

          buildInputs = with pkgs; [
            electron
          ];

          env = {
            # Tells Electron and Electron-builder to skip fetching pre-built binaries
            ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
            YOUTUBE_DL_SKIP_DOWNLOAD = "true";
            
            # Point Emscripten to a local cache to avoid permission errors in Nix sandbox
            EM_CACHE = ".emscripten_cache";
            
            # Set the distribution target as per AdvantageScope's build configs
            ASCOPE_DISTRIBUTION = "FRC 6328";
          };

          postPatch = ''
            # Strip out network-dependent postinstall scripts
            # We keep getLicenses.mjs and bundleLiteAssets.mjs as they can run offline
            substituteInPlace package.json \
              --replace-fail "cd docs && npm install && cd .. && node getLicenses.mjs && node tesseractLangDownload.mjs && node bundleLiteAssets.mjs && npm run download-owlet" "node getLicenses.mjs && node bundleLiteAssets.mjs"
          '';

          preBuild = ''
            # Setup a local cache for Emscripten WASM compilation
            mkdir -p $EM_CACHE
            
            # AdvantageScope requires C++ logic compiled to WebAssembly 
            npm run wasm:compile
          '';

          postBuild = ''
            # Package the app to an unpacked directory (skipping AppImage/Debian packaging)
            npm run build-linux -- --dir
          '';

          installPhase = ''
            runHook preInstall

            # Create the app directory structure
            mkdir -p $out/share/advantagescope
            
            # Copy the unpacked Linux application into the share directory
            cp -r dist/linux-unpacked/* $out/share/advantagescope/

            # Create an executable wrapper that relies on the system Nixpkgs Electron
            makeWrapper ${pkgs.electron}/bin/electron $out/bin/advantagescope \
              --add-flags $out/share/advantagescope/resources/app.asar

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Robot telemetry application for the FIRST Robotics Competition";
            homepage = "https://github.com/Mechanical-Advantage/AdvantageScope";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.linux;
            mainProgram = "advantagescope";
          };
        };

        # A handy devShell if you want to contribute to AdvantageScope locally
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            emscripten
            python3
            electron
          ];
          
          shellHook = ''
            export ELECTRON_SKIP_BINARY_DOWNLOAD=1
            export EM_CACHE="$PWD/.emscripten_cache"
          '';
        };
      }
    );
}
