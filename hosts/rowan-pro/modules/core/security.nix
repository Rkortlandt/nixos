{ config, lib, pkgs, ... }:

{
  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services.login.enableKwallet = true;
  security.pam.services.greetd.enableKwallet = true;

  #Force Chromium/Chrome/Brave to look for KWallet instead of guessing
  environment.sessionVariables = {
    CHROME_FLAGS = "--password-store=kwallet6"; 
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kwallet
    kdePackages.kwalletmanager # Optional graphical utility to manage it
  ];

  # TPM
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

	networking.firewall.allowedTCPPorts = [ 5173 3000 ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
