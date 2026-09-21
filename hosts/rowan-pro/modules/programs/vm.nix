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

  # Allow traffic on the libvirt NAT bridge so the default network
  # (and DHCP/DNS for guests) actually works. This is the most common
  # cause of "VM has no internet" on NixOS, since the firewall blocks
  # virbr0 by default.
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  # Virtual Machine Manager GUI
  programs.virt-manager.enable = true;

  # Add user to libvirt, QEMU, and KVM access groups
  users.users.ss-pro.extraGroups = [
    "kvm"
    "libvirtd"
    "qemu-libvirtd"
  ];

  # VM management, disk image, network bridge, and firmware packages
  environment.systemPackages = with pkgs; [
    qemu
    bridge-utils
    OVMFFull
    swtpm      # software TPM emulator - see note on the domain XML below
    looking-glass-client
    virtio-win
  ];

  # Looking Glass shared memory device
  # 2880x1800 resolution needs ~64MB (128MB gives room for 4K / HDR)
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ss-pro kvm -"
  ];

   # Enable the VMware Workstation host daemon and kernel modules
  virtualisation.vmware.host.enable = true;

  # Required fix: Prevent VMware from triggering kcompactd0 high CPU usage
  boot.kernelParams = [ "transparent_hugepage=never" ];
}
