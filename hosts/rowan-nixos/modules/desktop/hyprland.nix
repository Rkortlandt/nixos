{ lib, config, pkgs, inputs, ...}: with lib; let
  cfg = config.modules.hyprland;

  refreshRateUdevScript = pkgs.writeShellScript "hypr-refresh-rate-udev" ''
    for user_dir in /run/user/*; do
      [ -d "$user_dir" ] || continue
      uid="$(basename "$user_dir")"
      case "$uid" in
        '''|*[!0-9]*) continue ;;
      esac

      user_name="$(${pkgs.coreutils}/bin/id -nu "$uid" 2>/dev/null || true)"
      [ -n "$user_name" ] || continue

      user_hypr="$user_dir/hypr"
      if [ -d "$user_hypr" ]; then
        for inst in "$user_hypr"/*; do
          if [ -S "$inst/.socket.sock" ]; then
            inst_sig="$(basename "$inst")"
            user_home="$(eval echo "~$user_name")"
            for script_path in \
              "$user_home/nixos/home-manager/hyprland/hypr/scripts/refresh-rate.sh" \
              "$user_home/.config/hypr/scripts/refresh-rate.sh"; do
              if [ -x "$script_path" ]; then
                ${pkgs.util-linux}/bin/runuser -u "$user_name" -- env \
                  PATH="/home/$user_name/.nix-profile/bin:/etc/profiles/per-user/$user_name/bin:/run/current-system/sw/bin:$PATH" \
                  XDG_RUNTIME_DIR="$user_dir" \
                  HYPRLAND_INSTANCE_SIGNATURE="$inst_sig" \
                  "$script_path" auto </dev/null >/dev/null 2>&1 || true
                break
              fi
            done
          fi
        done
      fi
    done
  '';
in {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
    ./common.nix
  ];

  options.modules.hyprland.enable = mkEnableOption "Enable Hyprland"; 

  config = mkIf cfg.enable {
    programs = {
      hyprland.enable = true;
    };

    services.udev.extraRules = ''
      # Hyprland adaptive refresh rate switching on power supply state changes
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="${refreshRateUdevScript}"
      SUBSYSTEM=="power_supply", ATTR{type}=="USB", ACTION=="change", RUN+="${refreshRateUdevScript}"
    '';

/* 
    services.greetd = {
      enable = true;
      restart = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --user-menu --time --r --cmd Hyprland";
          user = "ss-rowan";
        };
        default_session = initial_session;
      };
    }; */
    services.displayManager = {
      ly = {
        enable = true;
        settings = {
          animation = "1";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      kitty
      dunst
      xdg-desktop-portal-hyprland
      brightnessctl
    ] ++ (with pkgs.unstable; [
      hypridle
      hyprlock
    ]);
  };
}
