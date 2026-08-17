{ config, lib, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    # Critical: Opens ports for streaming
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Steam needs 32-bit graphics libraries for hardware decoding
  hardware.graphics = {
    enable = true;
    enable32Bit = true; 
  };
}
