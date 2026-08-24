{ config, pkgs, ...} : {
  imports = [
# Paths to other modules.
# Compose this module out of smaller ones.
  ];

  options = {
# Option declarations.
# Declare what settings a user of this module module can set.
# Usually this includes a global "enable" option which defaults to false.

  };
  config = {
    powerManagement.powertop.enable = false;
    services.power-profiles-daemon.enable = true;
    powerManagement.enable = true;
    services.upower.enable = true;
    services.logind.settings.Login = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchDocked = "hybrid-sleep";
      lidSwitchExternalPower = "hybrid-sleep";
      powerKey = "hibernate";
      powerKeyLongPress = "poweroff";
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      # Needs investigation
      # powerManagement.finegrained = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

# Thermald is intel only
    services.thermald.enable = false;
# Not in use in favor of PPD
    services.tlp = {
      enable = false;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";

        CPU_SCALING_MAX_FREQ_ON_BAT = 3000000;

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;

        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;

# Prevent TLP from autosuspending I2C / touchpad drivers
        RUNTIME_PM_DRIVER_DENYLIST = "i2c_designware i2c_hid_acpi hid_multitouch";
      };
    };

    environment.systemPackages = with pkgs; [
    ];
  };
}
