{ lib, config, pkgs, inputs, ...}: with lib; let cfg = config.modules.hyprland; in {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];

  options.modules.hyprland.enable = mkEnableOption "Enable Hyprland"; 

  config = mkIf cfg.enable {
    programs = {
      hyprland.enable = true;
    };

    services.greetd = {
      enable = true;
      restart = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --user-menu --time --r --cmd Hyprland";
          user = "ss-rowan";
        };
        default_session = initial_session;
      };
    };

    environment.systemPackages = with pkgs; [
      dunst
      xdg-desktop-portal-hyprland
      brightnessctl
    ] ++ (with pkgs.unstable; [
      hypridle
      hyprlock
    ]);
  };
}
