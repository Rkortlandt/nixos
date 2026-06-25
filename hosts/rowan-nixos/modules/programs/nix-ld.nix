{ config, lib, pkgs, pkgs-legacy, ... }:

{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libsecret          # Fixes your current error
      expat
      glib
      gtk3
      xorg.libX11
      xorg.libXext
      xorg.libXxf86vm
      xorg.libSM        
      xorg.libICE        # Almost always required alongside libSM
      nss                # Network Security Services (Huge culprit for web-based UIs)
      nspr               # Pairs closely with NSS
      alsa-lib           # Web engines constantly look for audio, even if silent
      dbus               # Inter-process communication
      cups               # Printing (A classic Chromium/CEF quirk)
      xorg.libXcomposite # Standard X11 rendering extensions...
      xorg.libXdamage    
      xorg.libXfixes     
      xorg.libXrandr     
      xorg.libxcb        # X C Binding
      freetype
      libsoup_2_4
      libpng
      libjpeg
      mesa               # OpenGL/Hardware acceleration
      libxkbcommon
      stdenv.cc.cc.lib   # Often needed for standard C++ libraries
      atk                # <-- The one you just hit
      pango              # (Preemptive) Text rendering
      cairo              # (Preemptive) 2D graphics
      gdk-pixbuf         # (Preemptive) Image loading
    ] ++ [
      pkgs-legacy.webkitgtk
    ];
  };
}
