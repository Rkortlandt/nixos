#this is your home-manager configuration file

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
      ".lib/jdk17".source = pkgs.jdk17;
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
  };

  gtk = {
    enable = true;
    cursorTheme.package = pkgs.bibata-cursors;
    cursorTheme.name = "Bibata-Modern-Classic";
    iconTheme.package = pkgs.adwaita-icon-theme;
    iconTheme.name = "Adwaita";
  };

  qt = {
    enable = true;

    style.name = "dracula";
    style.package = pkgs.dracula-qt5-theme;
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

 services.dunst = {
    enable = true;
    settings = {
      global = {
        offset = "";
        corner_radius = 10;
        origin = "top-left";
        progress_bar = true;
        dmenu = "${pkgs.fuzzel}";
        follow = "mouse";
        font = "Droid Sans 10";
        format = "<b>%s</b>\\n%b";
        frame_color = "#000000";
        frame_width = 2;
        geometry = "500x5-5+30";
        horizontal_padding = 8;
        icon_position = "left";
        line_height = 0;
        markup = "full";
        padding = 8;
        separator_color = "frame";
        separator_height = 2;
        transparency = 0;
        word_wrap = true;
      };

      urgency_low = {
        background = "#000000";
        foreground = "#4da1af";
        timeout = 10;
      };

      urgency_normal = {
        background = "#000000";
        foreground = "#70a040";
        timeout = 15;
      };

      urgency_critical = {
        background = "#000000";
        foreground = "#dd5633";
        timeout = 0;
      };

      shortcuts = {
        context = "mod4+grave";
        close = "mod4+shift+space";
      };
    };
  };

 services.udiskie = {
   enable = true;
# The 'settings' attribute set is automatically translated into the
# ~/.config/udiskie/config.yml file for you.
   settings = {
     rules = [
     {
       name = "Ignore Windows Partition";
       ignore = true;
       match = {
         uuid = "6832EF5632EF27B0";
       };
     }
     {
       name = "Ignore Shared Partition";
       ignore = true;
       match = {
         uuid = "F67F-6912";
       };
     }
     ];
# You can set other udiskie options here as well
     program_options = {
       file_manager = "thunar"; # Optional: Change to your preferred file manager
     };
   };
 };


  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        "NIXOS_OZONE_WL,1" # for any ozone-based browser & electron apps to run on wayland
        "MOZ_ENABLE_WAYLAND,1" # for firefox to run on wayland
        "MOZ_WEBRENDER,1"
        "QT_SCALE_FACTOR,1"
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
        fzf
      ] ++ (with inputs.ags.packages.${pkgs.system}; [
        battery
        hyprland
        network
        wireplumber
        mpris
        tray
        greet
        bluetooth
      ]);
    };

    btop.enable = true;
    waybar.enable = true;
    starship.enable = true;
    kitty.enable = true;
    ripgrep.enable = true;

    git = {
      enable = true;
      settings.user = {
        email = "rowankortlandt@otsegops.org";
        name = "rkortlandt";
      };
    }; 

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
      };
    };
  };
 
/*     firefox.enable = true;
    firefox.profiles.rowan = {
      search = {
        default = "google";
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

      extensions.packages = with inputs.firefox-addons.packages."x86_64-linux"; [
        bitwarden
        ublock-origin
        sponsorblock
      ];
     }; 
  };
 */
home.packages = with pkgs; [
  #Stable
  prismlauncher
  swaybg
  snapshot
  gimp
  nemo
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
  python3
  go
  nodejs
  air
  libreoffice-qt
  cargo
  unzip
  rclone
  clipse
  cliphist
  blender
  spotify
  jetbrains.idea-ultimate
  jetbrains.rider
  qalculate-gtk
  libqalculate
  slack
  lua-language-server
  hyprpicker
  tofi
  inkscape
  dolphin-emu
  mpg123
  fuzzel
  rustc
  nixd
  taskwarrior3
  unityhub
] ++ (with pkgs.unstable; [
  #Unstable
  freecad
  musescore
  chromium
  cosmic-term
  arduino
  zig
  android-studio
  zed-editor
  godot_4
  bluetui
  orca-slicer
  vivaldi
]) ++ (with inputs; [
  zen-browser.packages."${system}".default
]);
  
  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
