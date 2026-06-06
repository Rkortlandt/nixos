vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.hlsearch = false
vim.cmd.transparentenable = true

vim.o.smartindent = true
vim.o.autoindent = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2

vim.wo.number = true

vim.o.mouse = 'a'

vim.o.breakindent = true

vim.o.undofile = true

-- case-insensitive searching unless \c or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = 'yes'
-- decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 2000

-- set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- note: you should make sure your terminal supports this
vim.o.termguicolors = true
-- disable space bar
vim.keymap.set({ 'n', 'v' }, '<space>', '<nop>', { silent = true })

-- error jumping
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'open floating diagnostic message' })
vim.keymap.set('n', '<leader>en', function() vim.diagnostic.jump({ count = 1, float=true}) end, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>ee', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- install lazy.nvim plugin manager 
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.nystem {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- PLUGINS
--
-- 
-- PLUGINS

local lspconfig = {
  -- lsp configuration & plugins
  'neovim/nvim-lspconfig',
  dependencies = {
    -- useful status updates for lsp
    { 'j-hui/fidget.nvim', opts = {} },
    { 'folke/neodev.nvim', opts = {} },
  },
}

local autocmp = {
  'hrsh7th/nvim-cmp',
  dependencies = {
    -- snippet engine & its associated nvim-cmp source
    'l3mon4d3/luasnip',
    'saadparwaiz1/cmp_luasnip',

    -- adds lsp completion capabilities
    'hrsh7th/cmp-nvim-lsp',

    -- adds a number of user-friendly snippets
    'rafamadriz/friendly-snippets',
  },
}

--[[ local llama = {
  "ggml-org/llama.vim",
  init = function()
    vim.g.llama_config = {
      endpoint_fim = "http://127.0.0.1:8012/infill",
      show_info = true, -- Displays green performance metrics in the status bar
      keymap_fim_accept_full = "<Tab>",
    }

    -- Fix any potential theme background clipping issues
    vim.api.nvim_set_hl(0, "LlamaSuggestion", { fg = "#808080", italic = true })
  end,
} ]]

local gitsigns = {
  'lewis6991/gitsigns.nvim',
  opts = {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
  },
}

local aerial = {
  'stevearc/aerial.nvim',
  opts = {},
  -- Optional dependencies
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
}

local whichkey = { 'folke/which-key.nvim', opts = {} }

local theme = {
  'olimorris/onedarkpro.nvim',
  priority = 1000,
  config = function()
    vim.cmd.colorscheme 'onedark_dark'
  end,
}

local lualine = {
  'nvim-lualine/lualine.nvim',
  opts = {
    options = {
      icons_enabled = true,
      theme = 'onedark',
      component_separators = '|',
      section_separators = '',
    },
  },
}

local indent = {
  -- add indentation guides even on blank lines
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  opts = {},
}

local comment = {
  'numtostr/comment.nvim',
  opts = {
    toggler = { line = '<leader>/'},
    opleader = { block = '<leader>/'}
  }
}

local telescope = {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- fuzzy finder algorithm which requires local dependencies to be built.
    -- only load if `make` is available. make sure you have the system
    -- requirements installed.
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      -- note: if you are having trouble with this installation,
      --       refer to the readme for telescope-fzf-native for more instructions.
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  opts = {
    defaults = {
      -- Use 'vertical' or 'flex' to allow top/bottom positioning
      layout_strategy = 'vertical',
      layout_config = {
        vertical = {
          preview_height = 0.5,
          mirror = true, -- Set to true to flip preview to bottom
        },
        -- Adjust the width to fit your screen
        width = 0.95,
        height = 0.95,
      },
      mappings = {
        i = {
          ['<c-u>'] = false,
          ['<c-d>'] = false,
        },
      },
    },
  },
}

local treesitter = {
  "nvim-treesitter/nvim-treesitter",
  build = ":tsupdate",
  config = function()
    local configs = require("nvim-treesitter.configs")
    configs.setup({
      -- add languages to be installed here that you want installed for treesitter
      ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash' },
      ignore_install = {},

      modules = {},
      sync_install = false,
      auto_install = true,

      highlight = { enable = true },
      indent = { enable = false },
    })
  end
}

local wakatime = {
  "wakatime/vim-wakatime",
  lazy = false,
}

local nvimtree = {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup {}
  end,
}

require('lazy').setup({
  lspconfig,
  autocmp,
  gitsigns,
  whichkey,
  theme,
  lualine,
  indent,
  telescope,
  comment,
  treesitter,
  wakatime,
  nvimtree,
  aerial,
  -- llama,

  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  'tpope/vim-sleuth',
  'junegunn/gv.vim',
  'xiyaowong/transparent.nvim',
  'nvim-lua/plenary.nvim',
  'theprimeagen/harpoon',
  'mfussenegger/nvim-jdtls',

  require 'kickstart.plugins.autoformat',
  -- require 'kickstart.plugins.debug',
}, {})

require("aerial").setup({
  -- optionally use on_attach to set keymaps when aerial has attached to a buffer
  on_attach = function(bufnr)
    vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
  end,
})

-- [[ highlight on yank ]]
-- see `:help vim.highlight.o 2 + 2 = 4n_yank()`
local highlight_group = vim.api.nvim_create_augroup('yankhighlight', { clear = true })
vim.api.nvim_create_autocmd('textyankpost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- telescope live_grep in git root
-- function to find the git root directory based on the current buffer's path
local function find_git_root()
  -- use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- if the buffer is not associated with a file, return nil
  if current_file == "" then
    current_dir = cwd
  else
    -- extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ":h")
  end

  -- find the git root directory from the current file's path
  local git_root = vim.fn.systemlist("git -c " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    print("not a git repository. searching on current working directory")
    return cwd
  end
  return git_root
end

-- custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep({
      search_dirs = { git_root },
    })
  end
end


vim.api.nvim_create_user_command('Livegrepgitroot', live_grep_git_root, {})

-- Remap <leader>y to yank (copy) to the system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })

-- Remap <leader>p to paste from the system clipboard
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Optional: Remap <leader>P for pasting before the cursor
vim.keymap.set({ "n" }, "<leader>P", '"+P', { desc = "Paste (before) from system clipboard" })

-- see `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] find existing buffers' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sG', ':Livegrepgitroot<cr>', { desc = '[S]earch by [G]rep on Git Root' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
vim.filetype.add({ extension = { templ = "templ" } })

-- [[ Configure LSP ]]
require("neodev").setup({})

local client_capabilities = vim.lsp.protocol.make_client_capabilities()
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities(client_capabilities)

local function setup_lsp_keymaps(_, bufnr)
  local function map_key(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
  end

  map_key('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
  map_key('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  map_key('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  map_key('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  map_key('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  map_key('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  map_key('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  map_key('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
  map_key('K', vim.lsp.buf.hover, 'Hover Documentation')
  map_key('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
  map_key('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  map_key('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
  map_key('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  map_key('<leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, '[W]orkspace [L]ist Folders')

  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_) vim.lsp.buf.format() end, { desc = 'Format current buffer with LSP' })
end

require('lspconfig').svelte.setup({
  capabilities = lsp_capabilities,
  on_attach = function(client, bufnr)
    setup_lsp_keymaps(client, bufnr)
    if client.name == 'svelte' then
      vim.api.nvim_create_autocmd('BufWritePost', {
        pattern = { '*.js', '*.ts' },
        callback = function(ctx)
          client:notify('$/onDidChangeTsOrJsFile', { uri = ctx.match })
        end,
      })
    end
  end,
})

require('lspconfig').jdtls.setup({
  capabilities = lsp_capabilities,
  settings = {
    java = {
      completion = {
        favoriteStaticMembers = {
          "edu.wpi.first.units.Units.*",
          "edu.wpi.first.wpilibj.SmartDashboard.*",
          "edu.wpi.first.wpilibj.util.Color.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
        },
      },
    },
  },
  on_attach = function(client, bufnr)
    setup_lsp_keymaps(client, bufnr)
    
    local function map_key(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
    end

    local jdtls_status, jdtls = pcall(require, 'jdtls')
    if jdtls_status then
      map_key('<leader>oi', jdtls.organize_imports, 'Java: [O]rganize [I]mports')
      map_key('<leader>ev', jdtls.extract_variable, 'Java: [E]xtract [V]ariable')
      map_key('<leader>ec', jdtls.extract_constant, 'Java: [E]xtract [C]onstant')
      map_key('<leader>bld', '<CMD>JdtCompile full<CR>', 'Java: [B]ui[ld] Project')
      map_key('<leader>td', function() require('telescope.builtin').diagnostics({ bufnr = nil }) end, '[T]elescope [D]iagnostics (Errors)')
      vim.keymap.set('v', '<leader>em', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], { buffer = bufnr, desc = 'LSP: Java: [E]xtract [M]ethod' })
    end
  end,
})

require('lspconfig').lua_ls.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
})

require('lspconfig').gopls.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
})

require('lspconfig').templ.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
})

require('lspconfig').htmx.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
  filetypes = { 'html', 'templ' },
})

-- (Keep your existing nvim-cmp, Telescope bindings, and autocmds down here)
-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert'
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}


-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
