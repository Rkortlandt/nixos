# This is your home-manager configuration file
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
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    inputs.nixneovim.nixosModules.homeManager-22-11
    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./nvim
    ./bash
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      inputs.nixneovimplugins.overlays.default
      inputs.nixneovim.overlays.default
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
      ".config/hypr".source = ./hyprland/hypr;
      ".config/waybar".source = ./hyprland/waybar;
      ".config/kitty".source = ./kitty;
      ".config/starship.toml".source = ./starship.toml;
      ".config/tofi".source = ./tofi;
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

  programs = {
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
    tofi 
    swaybg
    jetbrains.idea-ultimate
    obsidian
    grim
    slurp
    qemu
    bridge-utils
    discord
    vivaldi
    btop
    jdk21
    gcc
    gradle
    zoom
  ];
  
  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
