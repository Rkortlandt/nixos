#This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    inputs.ags.homeManagerModules.default
    ./bash
  ];
  
  nixpkgs = {
    # You can add overlays here
    overlays = [
      
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # }) 
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
        allowUnfree = true;
        permittedInsecurePackages = [
        "electron-25.9.0"
        "electron-13.6.9"
      ];
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "ss-rowan";
    homeDirectory = "/home/ss-rowan";
  };

  home.file = {
      ".config/hypr/NixWallpaper.jpg".source = ./hyprland/hypr/NixWallpaper.jpg;
      ".config/hypr/hypridle.conf".source = ./hyprland/hypr/hypridle.conf;
      ".config/hypr/hyprlock.conf".source = ./hyprland/hypr/hyprlock.conf;
      ".config/hypr/hyprpaper.conf".source = ./hyprland/hypr/hyprpaper.conf;
      ".config/waybar".source = ./hyprland/waybar;
      ".config/kitty".source = ./kitty;
      ".config/starship.toml".source = ./bash/starship.toml;
      ".config/tofi".source = ./tofi;
      ".lib/jdk11".source = pkgs.jdk11;
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
  };

  gtk = {
    enable = true;
    theme.name = "adw-gtk3-dark";
    theme.package = pkgs.adw-gtk3;
    cursorTheme.package = pkgs.bibata-cursors;
    cursorTheme.name = "Bibata-Modern-Classic";
    iconTheme.package = pkgs.gnome.adwaita-icon-theme;
    iconTheme.name = "Adwaita";
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

  services = {
    dunst.enable = true;
  };  

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        "NIXOS_OZONE_WL,1" # for any ozone-based browser & electron apps to run on wayland
        "MOZ_ENABLE_WAYLAND,1" # for firefox to run on wayland
        "MOZ_WEBRENDER,1"
        # misc
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
      ];
    };
    extraConfig = builtins.readFile ./hyprland/hypr/hyprland.conf;
  };

  programs = {
    ags = {
      enable = true;
      configDir = ./ags;
      extraPackages = with pkgs; [
        gtksourceview
        webkitgtk
        accountsservice
      ];
    };

    btop.enable = true;
    waybar.enable = true;
    starship.enable = true;
    kitty.enable = true;
    ripgrep.enable = true;

    git = {
      enable = true;
      userName = "rkortlandt";
      userEmail = "rowankortlandt@otsegops.org";
    }; 

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
      };
    };

    firefox.enable = true;
    firefox.profiles.rowan = {
      search = {
        default = "Bing";
        force = true;
       engines."Nix-Packages" = {
          urls = [{
            template = "https://search.nixos.org/packages";
            params = [
              { name = "type"; value = "packages";}
              { name = "query"; value = "{searchTerms}";}
            ];
          }];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@np" "@nix" "@packages" ];
        };
      };

      extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
        bitwarden
        ublock-origin
        sponsorblock
      ];
    }; 
  };

home.packages = with pkgs; [
  #Stable 
  tofi 
  swaybg
  obsidian
  grim
  slurp
  qemu
  bridge-utils
  discord
  btop
  jdk21
  gcc
  gradle
  python39
  go
  nodejs
  air
  libreoffice-qt
  cargo
  unzip
  rclone
  musescore
] ++ (with pkgs.unstable; [
  #Unstable
  vivaldi
  jetbrains.idea-ultimate
  cosmic-term
  arduino
  zig
]);
  
  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
