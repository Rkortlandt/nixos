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

    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    environment.systemPackages = with pkgs; [
    ] ++ (with pkgs.unstable; [
    ]);
  };
}
