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
    kitty
    localsend

    # Development
    # llama-cpp
    eza
    gcc
    jdk21
    python3
    go
    gopls
    nodejs
    cargo
    rustc
    gradle
    air
    lua-language-server
    svelte-language-server
    vscode-json-languageserver
    nil
    nixd
    delve
    jetbrains.idea
    jetbrains.rider
    llm-ls

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
    mathematica
    thunderbird

    # Gaming & Emulation
    dolphin-emu
    # unityhub
    wine
    bottles
  ] ++ (with pkgs.unstable; [
    # Desktop & Utilities
    # cosmic-term
    bluetui

    # Development & Game Engines
    zig
    zls
    typescript-language-server
    jdt-language-server
    arduino
    android-studio
    zed-editor
    godot_4
    gitkraken
    antigravity-cli

    # Browsers 
    chromium
    vivaldi

    # etc
    musescore
    orca-slicer
    prismlauncher
  ]) ++ (with inputs; [
    zen-browser.packages."${system}".default
    quickshell.packages."${system}".default
    #grab.packages."${system}".default
  ]);
}
