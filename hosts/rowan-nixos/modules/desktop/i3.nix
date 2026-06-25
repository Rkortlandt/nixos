{ lib, config, pkgs, inputs, ...}: with lib; let cfg = config.modules.i3; in {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];

  options.modules.i3.enable = mkEnableOption "Enable i3"; 

  config = mkIf cfg.enable {
    services.displayManager = {
        defaultSession = "none+i3";
    };
    services.xserver = {
      enable = true;
    

      desktopManager = {
        xterm.enable = false;
      };

      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu #application launcher most people use
            i3status # gives you the default i3 status bar
            i3lock #default i3 screen locker
            i3blocks #if you are planning on using i3blocks over i3status
        ];
      };

    };
    programs = {

    };

    environment.systemPackages = with pkgs; [
      brightnessctl
    ] ++ (with pkgs.unstable; [
    ]);
  };
}
