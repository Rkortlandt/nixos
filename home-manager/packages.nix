{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Desktop & Wayland
    adw-gtk3
    adwaita-icon-theme
    swaybg
    grim
    slurp
    hyprpicker
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
    nodejs
    cargo
    rustc
    gradle
    air
    lua-language-server
    nil
    nixd
    delve
    jetbrains.idea
    jetbrains.rider

    # Creative & Design
    gimp
    inkscape
    blender
    freecad
    spotify
    mpg123

    # Productivity & Communication
    discord
    slack
    obsidian
    taskwarrior3
    libreoffice-qt
    octaveFull

    # Gaming & Emulation
    prismlauncher
    dolphin-emu
    unityhub
    wine
    bottles
  ] ++ (with pkgs.unstable; [
    # Desktop & Utilities
    cosmic-term
    bluetui

    # Development & Game Engines
    zig
    zls
    typescript-language-server
    arduino
    android-studio
    zed-editor
    godot_4
    jdt-language-server
    gitkraken

    # Browsers 
    chromium
    vivaldi

    # etc
    musescore
    orca-slicer
  ]) ++ (with inputs; [
    zen-browser.packages."${system}".default
    grab.packages."${system}".default
  ]);
}
