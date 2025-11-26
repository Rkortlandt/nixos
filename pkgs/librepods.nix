# You can run this with: nix-build librepods.nix
#
# If it fails with a hash mismatch, copy the "got" hash
# from the error message and paste it over the "hash" value below.

{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation rec {
  pname = "librepods";
  version = "0.1.0-rc.4"; # Based on the latest tag in their repo

  # This fetches the source code
  src = fetchFromGitHub {
    owner = "kavishdevar";
    repo = "librepods";
    rev = "v${version}"; # Corresponds to the git tag "v0.2.0"

    # This is a placeholder hash. Nix will fail on the first run
    # and tell you the correct hash to put here.
    hash = "sha256-FnDYQ3EPx2hpeCCZvbf5PJo+KCj+YO+DNg+++UpZ7Xs=";
  };

  # The GitHub action runs in 'linux', so we do the same.
  # This tells Nix to 'cd' into the 'linux' directory after unpacking.
  sourceRoot = "source/linux";

  # These are the build tools (from build-essential, cmake, ninja-build)
  nativeBuildInputs = [
    cmake
    ninja
  ];

  # These are the libraries (from qt6-*-dev, libxkbcommon-dev)
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qttools
    qt6.qtconnectivity
    libxkbcommon
    qt6.wrapQtAppsHook
  ];

  # The GitHub workflow doesn't run "ninja install", it just
  # uploads the binary from the build/ directory.
  # We need to create an installPhase to copy the binary into the $out folder.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # The build runs 'ninja' in the 'build' dir (which mkDerivation creates).
    # The 'librepods' binary will be right in that directory.
    # We copy it to the standard $out/bin/librepods location.
    cp ./applinux $out/bin/librepods

    runHook postInstall
  '';

  # Standard metadata, good practice for Nix packages
  meta = with lib; {
    description = "A free and open source C++/Qt6 client for Apple's AirPods";
    homepage = "https://librepods.org/";
    license = licenses.gpl3Only; # I checked their repo for this
    platforms = platforms.linux;
  };
}
