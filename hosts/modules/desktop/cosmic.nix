{ lib, config, pkgs, inputs, ...}: with lib; let cfg = config.modules.cosmic; in {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];

  options.modules.cosmic.enable = mkEnableOption "Enable Cosmic"; 

  config = mkIf cfg.enable {
    programs = {
     
    };

      # Enable the login manager
  services.displayManager.cosmic-greeter.enable = true;
  # Enable the COSMIC DE itself
  services.desktopManager.cosmic.enable = true;
  # Enable XWayland support in COSMIC
  services.desktopManager.cosmic.xwayland.enable = true;

    environment.systemPackages = with pkgs; [
      cosmic-files
    ] ++ (with pkgs.unstable; [
    ]);
  };
}
