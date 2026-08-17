{ lib, config, pkgs, ...}: with lib; let cfg = config.modules.gnome; in {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];


  options.modules.gnome.enable = mkEnableOption "Enable Gnome"; 

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.systemPackages = with pkgs; [
      gnomeExtensions.pop-shell
    ];

  };
                                                                        }
