{ config, pkgs, ...} : {
  imports = [
  ];

  options = {
  };

  config = {
    environment.systemPackages = with pkgs; [
    # Desktop & Wayland
    adw-gtk3
    adwaita-icon-theme
    swaybg
    grim
    slurp
    tofi
    fuzzel
    clipse
    cliphist

    # Core Utilities
    nemo
    btop
    unzip
    rclone
    snapshot
    qalculate-gtk
    libqalculate
    qemu
    bridge-utils

    # Development
    gcc
    jdk21
    python3
    go
    gopls
		svelte-language-server
    lua-language-server
    nodejs
    cargo
    rustc
    gradle
    air
    nil
    nixd
    delve

    # Productivity & Communication
    libreoffice-qt

    # Gaming & Emulation
    wine
    bottles
  ] ++ (with pkgs.unstable; [
    # Desktop & Utilities
    bluetui

    # Development & Game Engines
    zig
    zls
    typescript-language-server
    arduino
    godot_4
    jdt-language-server
    gitkraken

    # Browsers 
    chromium

  ]) ++ (with inputs; [
    grab.packages."${system}".default
  ]);

  };
}
