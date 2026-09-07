{ config, pkgs, ... }:

{
  # Virtualisation / libvirtd configuration
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
    };
  };

  # Virtual Machine Manager GUI
  programs.virt-manager.enable = true;

  # Add user to libvirt and QEMU access groups
  users.users.ss-pro.extraGroups = [
    "libvirtd"
    "qemu-libvirtd"
  ];

  # VM management, disk image, network bridge, and firmware packages
  environment.systemPackages = with pkgs; [
    qemu
    bridge-utils
    OVMFFull
  ];
}
