{ config, pkgs, ...} : {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
  ];

  options = {
# Option declarations.
# Declare what settings a user of this module module can set.
# Usually this includes a global "enable" option which defaults to false.

  };

  config = {
    boot.loader = {
      grub2-theme = {
        enable = true;
        theme = "whitesur";
        footer = true;
      };

      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = false;
      };
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        devices = ["nodev"];
        useOSProber = true;
      };
    };
  };
}
