{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../modules/core/users.nix
    ../modules/core/security.nix
    ../modules/core/networking.nix
    ../modules/core/boot.nix
    
    ../modules/programs/nix-ld.nix
    ../modules/programs/steam.nix

    ../modules/desktop/hyprland.nix
    ../modules/desktop/kde.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "libsoup-2.74.3"
      ];
    };
  };

  nix = {
    registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);
    nixPath = ["/etc/nix/path"];
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

	programs.ladybird.enable = true;

  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  networking.hostName = "rowan-nixos";

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 44100;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 512;
      };
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  programs.dconf.enable = true;
  programs.virt-manager.enable = true;

  modules.hyprland.enable = lib.mkDefault true;

  specialisation = {
    kde.configuration = {
      modules.hyprland.enable = false;
      modules.kde.enable = true;
    };
  };

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;
  services.printing.enable = true;
  services.upower.enable = true;
  services.envfs.enable = true;

  services.logind.settings.Login = {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchDocked = "hybrid-sleep";
    lidSwitchExternalPower = "hybrid-sleep";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common = {
      default = ["hyprland" "gtk"];
    };
  };

  fonts.packages = with pkgs; [
    font-awesome
    helvetica-neue-lt-std
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono
  ];

  environment.systemPackages = with pkgs; [
    gnome-bluetooth_1_0
    gh
    kicad-small
    firefox
    neovim 
    ripgrep
    efibootmgr
    inkscape
    lm_sensors
    wl-clipboard
    socat
    jq
    libnotify
    jetbrains.gateway
    trash-cli
  ];

  time.timeZone = "America/Detroit";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  fileSystems."/home/sshdev/5152_project" = {
    device = "/home/ss-rowan/Documents/codeProjects-Git/5152_Rebuilt";
    options = [ "bind" ];
  };

  fileSystems."/home/sshdev/JDKS" = {
    device = "/home/ss-rowan/.jdks";
    options = [ "bind" ];
  }; 

  system.stateVersion = "23.05";
}
