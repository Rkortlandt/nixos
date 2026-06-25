{ config, pkgs, ...} : {
  imports = [
  ];

  options = {
  };

  config = {
    boot.loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };
}
