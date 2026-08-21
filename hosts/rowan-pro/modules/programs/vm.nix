
{ config, pkgs, ...} : {
virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
  };
};

programs.virt-manager.enable = true;
}
