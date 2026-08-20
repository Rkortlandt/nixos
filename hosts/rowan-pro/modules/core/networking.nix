{ config, lib, pkgs, ... }:

{
  # Networking
  networking.networkmanager.enable = true;

  networking = {
    firewall = {
      enable = true; 
      allowedTCPPorts = [ 8080 12345 22 8090 5173 53317 ];
      allowedUDPPorts = [ 53317 ];
      trustedInterfaces = [ "tailscale0" "thunderbolt0"];
    };
    interfaces.thunderbolt0 = {
      ipv4.addresses = [{
        address = "10.0.50.1";
        prefixLength = 24;
      }];
    };
  };


  boot.kernelModules = [ "thunderbolt-net" ];
  services.hardware.bolt.enable = true;

  # Avahi and NSS mDNS support
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;

    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };

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
}
