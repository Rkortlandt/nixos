{ config, lib, pkgs, ... }:

{
  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services.login.enableKwallet = true;

  #Force Chromium/Chrome/Brave to look for KWallet instead of guessing
  environment.sessionVariables = {
    CHROME_FLAGS = "--password-store=kwallet6"; 
  };

  # TPM
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

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
