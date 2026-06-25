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
    environment.systemPackages = with pkgs; [
      kitty
      firefox
    ];
  };
}
