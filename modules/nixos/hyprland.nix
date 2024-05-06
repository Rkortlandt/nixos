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
      thunar.enable = true;
      hyprland.enable = true;
    };

    services.greetd = {
      enable = true;
      restart = true;
      vt = 2;
      settings = rec {
        initial_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --remember --cmd Hyprland";
          user = "ss-rowan";
        };
        default_session = initial_session;
      };
    };

    environment.systemPackages = with pkgs; [
      dunst
      xdg-desktop-portal-hyprland
    ];
  };
}
