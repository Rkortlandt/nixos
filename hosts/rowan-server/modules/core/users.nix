{ config, lib, pkgs, ... }:

{
  users.groups.developers = {};

  users.users = {
    ss-server = {
      initialPassword = "password";
      isNormalUser = true;
      description = "Rowan Kortlandt";
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = [
        "wheel" 
        "networkmanager" 
        "audio" 
        "input" 
        "libvirtd" 
        "tss" 
        "docker" 
        "qemu-libvirtd" 
        "dialout" 
        "developers"
      ];
    };

   /*  sshdev = {
      initialPassword = "password";
      isNormalUser = true;
      description = "Sean";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtGkfL+J88kgpqGz6BWG2hOiGhjClM+8osMiH66DbFi sernstes@DESKTOP-MVFR5OM"
      ];
      extraGroups = ["developers"];
    }; */
  };
}
