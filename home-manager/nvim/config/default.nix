{ pkgs, lib,...}:{
  # Import all your configuration modules here
  imports = [
    ./options.nix
  ];
  
  programs.nixvim = {
  globals.mapleader = " ";
  colorschemes.onedark.enable = true;
  clipboard.providers.wl-copy.enable = true;
  enable = true; 
  
  keymaps = [
    {
      action = "<cmd>Telescope live_grep<CR>";
      key = "<leader>g";
    }
  ];

  plugins = {
    bufferline.enable = true;
    lualine.enable = true;
    telescope.enable = true;
    which-key.enable = true;
    treesitter.enable = true;
    luasnip.enable = true;
    nix.enable = true;
    treesitter-refactor.enable = true;
  };

 # extraPlugins = with pkgs.vimPlugins; [
 #   nvim-transparent
 # ];


  plugins.nvim-cmp = {
    enable = true;
    autoEnableSources = true;
    sources = [
      {name = "nvim_lsp";}
      {name = "path";}
      {name = "buffer";}
      {name = "luasnip";}
    ];

    mapping =  {
      "<C-Space>" = "cmp.mapping.complete()";
      "<C-d>" = "cmp.mapping.scroll_docs(-4)";
      "<C-e>" = "cmp.mapping.close()";
      "<C-f>" = "cmp.mapping.scroll_docs(4)";
      "<CR>" = "cmp.mapping.confirm({ select = true })";
      "<S-Tab>" = {
        action = "cmp.mapping.select_prev_item()";
        modes = [
          "i"
          "s"
        ];
      };
      "<Tab>" = {
        action = "cmp.mapping.select_next_item()";
        modes = [
          "i"
          "s"
        ];
      };
    };
  };
  plugins.lsp = {
    enable = true;

    servers = {
      tsserver.enable = true;
      clangd.enable = true;
      cmake.enable = true;
      rnix-lsp.enable = true;
      tailwindcss.enable = true;
      gopls.enable = true;
      lua-ls = {
        enable = true;
        settings.telemetry.enable = false;
      };
    };
  };
  };
}
