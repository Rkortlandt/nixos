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

    ./modules/core/users.nix
    ./modules/core/security.nix
    ./modules/core/networking.nix
    ./modules/core/boot.nix
    ./modules/core/performance.nix
    
    ./modules/programs/nix-ld.nix
    ./modules/programs/steam.nix

    ./modules/desktop/hyprland.nix
    ./modules/desktop/kde.nix
    ./modules/programs/vm.nix
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
  boot.kernelPackages = pkgs.linuxPackages_latest;


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
services.tailscale.enable = true;
services.asusd.enable = true;

  systemd.services.samba-smbd.after = [ "tailscaled.service" ];

 /*  services.samba = {
    enable = true;
    nmbd.enable = false;
    winbindd.enable = false;
    openFirewall = true;
    settings = {
      global = {
        "security" = "user";
        "map to guest" = "bad user";
        "disable netbios" = "yes";
        "smb ports" = "445";
      };
      "dropzone" = {
        "path" = "/home/ss-rowan/tailscale_drop";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "ss-rowan";
      };
    };
  };
  programs.ladybird.enable = true; */

  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  networking.hostName = "rowan-proart";


  hardware.graphics.enable = true; 

services.xserver.videoDrivers = [ "nvidia" ];

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  programs.dconf.enable = true;

  modules.hyprland.enable = lib.mkDefault true;

  specialisation = {
    kde.configuration = {
      modules.hyprland.enable = false;
      modules.kde.enable = true;
    };
  };

  virtualisation.docker.enable = true;

  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;
  services.printing.enable = true;
  services.envfs.enable = true;
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
 fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    font-awesome
      helvetica-neue-lt-std
      nerd-fonts._0xproto
      nerd-fonts.droid-sans-mono
      roboto
      inter
      carlito
      open-sans
      lato
      montserrat

# Microsoft Compatibility (Arial, Times New Roman, Calibri, etc.)
      corefonts
# Standard Apple/Linux Alternatives & Linux Defaults
      liberation_ttf
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
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
    asusctl
    git-lfs
    nemo-with-extensions
    nemo-fileroller
  ];

hardware.asus-dialpad-driver = {
  enable = true;
  daemon.enable = true;
  sessionTypes = [ "wayland" ];
  layout = "proartp16";

  defaultConfig = {
    app_shortcuts = {
      none = {
        clockwise = [
          {
            command = "hyprctl dispatch splitratio +0.02";
            trigger = "immediate";
            title = "Split Grow";
          }
        ];
        counterclockwise = [
          {
            command = "hyprctl dispatch splitratio -0.02";
            trigger = "immediate";
            title = "Split Shrink";
          }
        ];
        center = [
          {
            command = "hyprctl dispatch splitratio exact 0.5";
            trigger = "release";
            title = "Split Reset";
          }
        ];
      };
    };
  };
};

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

  system.stateVersion = "26.05";
}
