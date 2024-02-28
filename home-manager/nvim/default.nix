{ pkgs, lib, ...}:

{
  programs.nixvim = {
    defaultEditor = true;
    enable = true;
    colorschemes.onedark.enable = true;
    globals.mapleader = " ";
    options = import ./options.nix;

    plugins = {
      lspconfig = {
        enable = true;
        servers = {
          hls.enable = true;
          rust-analyzer.enable = true;
	  rnix-lsp.enable = true;
	  bashls.enable = true;
	  cssls.enable = true;
	  gopls.enable = true;
	  html.enable = true;
	  eslint.enable = true;
	  clangd.enable = true;
        };
      };
      fugitive.enable = true;

      treesitter = {
        enable = true;
	installAllGrammars = true;
	
      };
      indent-blankline.enable = true;
      which-key.enable = true;
      gitsigns.enable = true;
      lualine = {
        enable = true;
	theme = "onedark";
	sectionSeparators = {
	  left = "";
	  right = "";
	};
      };
      telescope.enable = true;
    };
    extraPlugins = with pkgs.vimExtraPlugins; [ 
      nvim-transparent
      neo-tree-nvim
      neodev-nvim
    ];
  };
}
