{ lib, config, pkgs, ...}: with lib; let cfg = config.modules.kde; in {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];


  options.modules.kde.enable = mkEnableOption "Enable KDE"; 

  config = mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
    # services.displayManager.plasma-login-manager.enable = true;

    environment.systemPackages = with pkgs; [
    ];

  };
                                                                        }
