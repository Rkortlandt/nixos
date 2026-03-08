# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    freecad = final.unstable.freecad.overrideAttrs (oldAttrs: rec {
      version = "1.1.0"; # Update this to the exact release tag if different

      src = final.fetchFromGitHub {
        owner = "FreeCAD";
        repo = "FreeCAD";
        tag = version;
        # We use fakeHash first. Nix will fail the build and print the correct one.
        hash = final.lib.fakeHash; 
        fetchSubmodules = true;
      };

      # The 1.0.2 derivation uses patches that will almost certainly fail to apply 
      # to the 1.1 source code. We clear them out to start fresh.
      patches = [ ]; 
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
