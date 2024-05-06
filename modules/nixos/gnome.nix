{ config, pkgs, ...} : {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];

  options = {
# Option declarations.
# Declare what settings a user of this module module can set.
# Usually this includes a global "enable" option which defaults to false.

  };

  config = {
    programs = {
      services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      gnomeExtensions.pop-shell
    ];
  };
}
