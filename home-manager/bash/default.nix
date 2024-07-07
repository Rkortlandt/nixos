{ pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyFileSize = 10000;
    historySize = 500;
    historyControl = [
      "erasedups"
      "ignoredups"
      "ignorespace"
    ];
    shellAliases = {
      cp = "cp -i";
      mv = "mv -i";
      mkdir = "mkdir -p";
      ps = "ps aixf";
      ping = "ping -c 10";
      less = "less -R";
      cls = "clear";
      apt-get = "suto apt-get";
      vi = "nvim";
      vim = "nvim";
      home = "cd ~";
      "cd.." = "cd ..";
      la = "ls -ALh";
      ls = "ls -aFh --color=always";
      ll = "ls -Fls";
      h = "history | grep";
      htop = "btop";
      top = "btop";
      mktar = "tar -cvf";
      mkbz2 = "tar -cvjf";
      mkgz = "tar -cvzf";
      untar = "tar -xvf";
      unbz2 = "tar -xvjf";
      ungz = "tar -xvzf";
      quit = "exit";
      whatismyip = "whatsmyip";
      exec = "hyprctl dispatch exec";
      nix = "nom";
      rnix = "sudo nixos-rebuild switch --flake ~/nixos/#rowan-nixos";
      rhome = "home-manager switch --flake ~/nixos/#ss-rowan@rowan-nixos";
      rnixboot = "sudo nixos-rebuild boot --install-bootloader --flake ~/nixos/#rowan-nixos";
    };

    initExtra = ''
	export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:' 
    
up ()
{
	local d=""
	limit=$1
	for ((i=1 ; i <= limit ; i++))
		do
			d=$d/..
		done
	d=$(echo $d | sed 's/^\///')
	if [ -z "$d" ]; then
		d=..
	fi
	cd $d
}

    '';
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.autojump = {
    enable = true;
    enableBashIntegration = true;
  };
}

