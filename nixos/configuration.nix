{
  inputs,
    outputs,
    lib,
    config,
    pkgs,
    pkgs-unstable,
    ...
}: {
  imports = [
    ./hardware-configuration.nix
      ../modules/nixos/gnome.nix
      ../modules/nixos/hyprland.nix
      ../modules/nixos/i3.nix
      ../modules/nixos/boot.nix
  ];

  nixpkgs = {
    overlays = [
      inputs.templ.overlays.default
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.unstable-packages
        inputs.templ.overlays.default
    ];
    config = {
      allowUnfree = true;
    };
  };

# This will add each flake input as a registry
# To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

# This will additionally add your inputs to the system's legacy channels
# Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
     name = "nix/path/${name}";
     value.source = value.flake;
     })
  config.nix.registry;

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };
#Networking
  networking.networkmanager.enable = true;

# Hostname
  networking.hostName = "rowan-nixos";

# Bootloader 

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  security.polkit.enable = true;
  security.rtkit.enable = true;
#TPM
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
#Audio
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

 

  modules.hyprland.enable = lib.mkDefault true;
  modules.gnome.enable = lib.mkDefault false;
  modules.i3.enable = lib.mkDefault false;
  programs.virt-manager.enable = true;


  virtualisation.docker.enable = true;
  services.fwupd.enable = true;
  services.gvfs.enable = true;  
  services.dbus.enable = true;
  services.printing.enable = true;
  services.upower.enable = true;
  services.envfs.enable = true;

  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchDocked = "hybrid-sleep";
    lidSwitchExternalPower = "hybrid-sleep";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

 /*  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  }; */

   # 1. Enable Avahi and NSS mDNS support
  services.avahi = {
    enable = true;
    nssmdns = true; # Enable Name Service Switch (NSS) support for mDNS
    openFirewall = true; # Open firewall for Avahi mDNS traffic (port 5353)

    # Publish services
    publish = {
      enable = true;
      addresses = true; # Publish your computer's IP addresses
      workstation = true; # Publish your workstation details
      userServices = true; # Allow publishing user-defined services
    };

    # Define your custom service
    extraServiceFiles = {
      "my-local-service.service" = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h My Local Service</name>
          <service>
            <type>_http._tcp</type> <port>9002</port>
            <txt-record>path=/</txt-record>
            <txt-record>description=My application on port 9002</txt-record>
          </service>
        </service-group>
      '';
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk  # For Thunar and other GTK applications
        xdg-desktop-portal-hyprland
    ];
    config.common = {
      default = ["hyprland" "gtk"];
    };
  };

#Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
#Enable virtualization
  virtualisation.libvirtd.enable = true;

#Fonts
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
    git
    firefox
    tofi
    swaybg
    unzip
    neovim 
    ripgrep
    udiskie
    efibootmgr
    # templ
    inkscape
    lm_sensors
    wl-clipboard
  ];

  services.openssh = {
    enable = true;
    settings = {
#Forbid root login through SSH.
      PermitRootLogin = "no";
# Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
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

  users.users = {
    ss-rowan = {
      initialPassword = "password";
      isNormalUser = true;
      description = "Rowan Kortlandt";
      openssh.authorizedKeys.keys = [
# TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = ["wheel" "networkmanager" "audio" "input" "libvirtd" "tss" "docker" "qemu-libvirtd" "dialout"];
    };
  };



# https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
