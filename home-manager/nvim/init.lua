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
-- disable default redundant mode indicator (shown in statusline)
vim.o.showmode = false
-- disable space bar
vim.keymap.set({ 'n', 'v' }, '<space>', '<nop>', { silent = true })

-- error jumping
vim.keymap.set('n', '<leader>ee', vim.diagnostic.open_float, { desc = 'open floating diagnostic message' })
vim.keymap.set('n', '<leader>en', function() vim.diagnostic.jump({ count = 1, float = true }) end,
  { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>el', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- install lazy.nvim plugin manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
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
      endpoint_fim = "http://127.0.0.1:11434/infill",
      show_info = true, -- Displays green performance metrics in the status bar
      keymap_fim_accept_full = "<Tab>",
    }

    -- Fix any potential theme background clipping issues
    vim.api.nvim_set_hl(0, "LlamaSuggestion", { fg = "#808080", italic = true })
  end,
} ]]

local aicmp = {
  "huggingface/llm.nvim",
  opts = {
    backend = "ollama",
    model = "deepseek-coder:1.3b-base",
    url = "http://localhost:11434",
    debounce_ms = 150,
    request_body = {
      options = {
        temperature = 0.2,
        top_p = 0.95,
        num_predict = 264,
        stop = { "\n\n", "<｜fim▁hole｜>", "<｜end▁of▁sentence｜>", "<｜fim▁begin｜>", "<｜fim▁end｜>" },
      }
    },
    fim = {
      enabled = true,
      prefix = "<｜fim▁begin｜>",
      middle = "<｜fim▁end｜>",
      suffix = "<｜fim▁hole｜>"
    },
    tokens_to_clear = { "<｜end▁of▁sentence｜>", "<｜fim▁end｜>" },
    lsp = {
      bin_path = vim.fn.exepath("llm-ls"),
      cmd_env = { LLM_LOG_LEVEL = "DEBUG" },
    },
    tokenizer = {
      repository = "deepseek-ai/deepseek-coder-1.3b-base",
    },
    context_window = 4096,
    enable_suggestions_on_startup = false,
    enable_suggestions_on_files = "*",
  },
  config = function(_, opts)
    require("llm").setup(opts)

    vim.keymap.set("i", "<Tab>", function()
      local completion = require("llm.completion")
      if completion.shown_suggestion ~= nil then
        completion.complete()
      else
        local tab_key_code = vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
        vim.api.nvim_feedkeys(tab_key_code, "n", false)
      end
    end, { expr = false, silent = true })
  end,
}

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
  config = function()
    -- Colors matching Tmux and Starship config
    local colors = {
      bg         = '#0d0f18', -- Dark bar background (tmux bar)
      fg         = '#fffaf3', -- Cream white text (tmux & starship)
      slate      = '#3B4252', -- Nord slate (starship directory & tmux session)
      navy       = '#0F5880', -- Deep navy blue (starship nix & tmux uptime)
      ocean      = '#0c6da3', -- Ocean blue (starship git branch)
      vivid_blue = '#0D77B1', -- Vivid blue (starship languages & tmux window)
      teal       = '#0A7883', -- Teal (tmux window status)
      mint       = '#0EA16F', -- Mint/Sea green (starship docker)
      emerald    = '#03883B', -- Emerald green (starship time & tmux active window)
      yellow     = '#ffd141', -- Yellow (tmux prefix & bell)
      red        = '#DF2500', -- Red (starship root)
      line       = '#3B4252', -- Solid horizontal line color
      inactive   = '#1e222a',
    }

    -- Mode-adaptive colors
    local mode_colors = {
      n = colors.emerald,
      i = colors.vivid_blue,
      v = colors.yellow,
      ['\22'] = colors.yellow,
      V = colors.yellow,
      c = colors.mint,
      no = colors.emerald,
      s = colors.yellow,
      S = colors.yellow,
      ['\19'] = colors.yellow,
      ic = colors.yellow,
      R = colors.red,
      Rv = colors.red,
      cv = colors.red,
      ce = colors.red,
      r = colors.red,
      rm = colors.red,
      ['r?'] = colors.red,
      ['!'] = colors.mint,
      t = colors.vivid_blue,
    }

    local custom_theme = {
      normal = {
        a = { fg = colors.fg, bg = colors.emerald, gui = 'bold' },
        b = { fg = colors.fg, bg = colors.navy },
        c = { fg = colors.line, bg = colors.bg },
        x = { fg = colors.fg, bg = colors.navy },
        y = { fg = colors.fg, bg = colors.vivid_blue },
        z = { fg = colors.fg, bg = colors.emerald, gui = 'bold' },
      },
      insert = {
        a = { fg = colors.fg, bg = colors.vivid_blue, gui = 'bold' },
        b = { fg = colors.fg, bg = colors.navy },
        c = { fg = colors.line, bg = colors.bg },
        x = { fg = colors.fg, bg = colors.navy },
        y = { fg = colors.fg, bg = colors.vivid_blue },
        z = { fg = colors.fg, bg = colors.emerald, gui = 'bold' },
      },
      visual = {
        a = { fg = colors.bg, bg = colors.yellow, gui = 'bold' },
        b = { fg = colors.fg, bg = colors.navy },
        c = { fg = colors.line, bg = colors.bg },
        x = { fg = colors.fg, bg = colors.navy },
        y = { fg = colors.fg, bg = colors.vivid_blue },
        z = { fg = colors.fg, bg = colors.emerald, gui = 'bold' },
      },
      command = {
        a = { fg = colors.fg, bg = colors.mint, gui = 'bold' },
        b = { fg = colors.fg, bg = colors.navy },
        c = { fg = colors.line, bg = colors.bg },
        x = { fg = colors.fg, bg = colors.navy },
        y = { fg = colors.fg, bg = colors.vivid_blue },
        z = { fg = colors.fg, bg = colors.emerald, gui = 'bold' },
      },
      replace = {
        a = { fg = colors.fg, bg = colors.red, gui = 'bold' },
        b = { fg = colors.fg, bg = colors.navy },
        c = { fg = colors.line, bg = colors.bg },
        x = { fg = colors.fg, bg = colors.navy },
        y = { fg = colors.fg, bg = colors.vivid_blue },
        z = { fg = colors.fg, bg = colors.emerald, gui = 'bold' },
      },
      inactive = {
        a = { fg = colors.slate, bg = colors.bg, gui = 'bold' },
        b = { fg = colors.slate, bg = colors.bg },
        c = { fg = colors.slate, bg = colors.bg },
        x = { fg = colors.slate, bg = colors.bg },
        y = { fg = colors.slate, bg = colors.bg },
        z = { fg = colors.slate, bg = colors.bg },
      },
    }

    -- Set statusline and fillchars
    vim.opt.fillchars:append({ stl = '─', stlnc = '─' })
    local function set_statusline_hl()
      vim.api.nvim_set_hl(0, 'StatusLine', { bg = colors.bg, fg = colors.line })
      vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = colors.bg, fg = colors.line })
    end
    set_statusline_hl()
    vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
      callback = set_statusline_hl,
    })

    -- Git pill component (branch + diff indicators)
    local function git_component()
      local head = vim.fn.FugitiveHead and vim.fn.FugitiveHead()
      if not head or head == '' then
        local dict = vim.b.gitsigns_status_dict
        head = dict and dict.head or ''
      end
      if head == '' then return '' end
      local dict = vim.b.gitsigns_status_dict
      local diff = ''
      if dict then
        if dict.added and dict.added > 0 then diff = diff .. ' +' .. dict.added end
        if dict.changed and dict.changed > 0 then diff = diff .. ' ~' .. dict.changed end
        if dict.removed and dict.removed > 0 then diff = diff .. ' -' .. dict.removed end
      end
      return ' ' .. head .. diff
    end

    -- LSP & Diagnostics status
    local function lsp_info()
      local parts = {}
      local num_errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
      local num_warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
      local num_info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
      local num_hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })

      if num_errors > 0 then table.insert(parts, '󰅚 ' .. num_errors) end
      if num_warnings > 0 then table.insert(parts, '󰀪 ' .. num_warnings) end
      if num_info > 0 then table.insert(parts, '󰋽 ' .. num_info) end
      if num_hints > 0 then table.insert(parts, '󰌶 ' .. num_hints) end

      local clients = vim.lsp.get_clients({ bufnr = 0 })
      local names = {}
      for _, c in ipairs(clients) do
        if c.name ~= 'null-ls' and c.name ~= 'copilot' and c.name ~= 'llm' then
          table.insert(names, c.name)
        end
      end
      if #names > 0 then
        table.insert(parts, '󰗀 ' .. table.concat(names, ','))
      end

      if #parts == 0 then return '' end
      return table.concat(parts, ' ')
    end

    require('lualine').setup({
      options = {
        theme = custom_theme,
        section_separators = '',
        component_separators = '',
        disabled_filetypes = { 'neo-tree', 'NvimTree' },
        icons_enabled = true,
      },
      sections = {
        -- LEFT SIDE: Pill capsules
        lualine_a = {
          -- Mode pill
          {
            'mode',
            fmt = function(str) return ' ' .. str end,
            color = function()
              local m = vim.fn.mode()
              local bg = mode_colors[m] or colors.emerald
              local fg = (m:find('^[vV\22sS\19]') or m == 'ic') and colors.bg or colors.fg
              return { bg = bg, fg = fg, gui = 'bold' }
            end,
            separator = { left = '', right = '' },
          },
          -- Spacer between mode and git
          {
            function() return ' ' end,
            padding = 0,
            color = { bg = colors.bg },
            cond = function() return git_component() ~= '' end,
          },
          -- Git branch & diff pill
          {
            git_component,
            color = { bg = colors.navy, fg = colors.fg },
            separator = { left = '', right = '' },
            cond = function() return git_component() ~= '' end,
          },
          -- Spacer between git and file
          {
            function() return ' ' end,
            padding = 0,
            color = { bg = colors.bg },
          },
          -- Filename pill
          {
            'filename',
            file_status = true,
            path = 1,
            symbols = {
              modified = ' ●',
              readonly = ' 󰌾',
              unnamed = '[No Name]',
              newfile = ' [New]',
            },
            color = { bg = colors.slate, fg = colors.fg },
            separator = { left = '', right = '' },
          },
        },
        lualine_b = {},
        lualine_c = {},
        -- RIGHT SIDE: Starship style continuous chevrons + rounded corner
        lualine_x = {
          {
            lsp_info,
            color = { bg = colors.navy, fg = colors.fg },
            separator = { left = '' },
            cond = function() return lsp_info() ~= '' end,
          },
        },
        lualine_y = {
          {
            'filetype',
            separator = { left = '' },
            color = { bg = colors.vivid_blue, fg = colors.fg },
          },
        },
        lualine_z = {
          {
            'progress',
            separator = { left = '' },
            color = { bg = colors.mint, fg = colors.fg },
          },
          {
            'location',
            separator = { left = '', right = '' },
            color = { bg = colors.emerald, fg = colors.fg, gui = 'bold' },
          },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            'filename',
            file_status = true,
            path = 1,
            color = { bg = colors.slate, fg = colors.fg },
            separator = { left = '', right = '' },
          },
        },
        lualine_x = { { 'location', separator = { left = '', right = '' } } },
        lualine_y = {},
        lualine_z = {},
      },
    })
  end,
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
    toggler = { line = '<leader>/' },
    opleader = { block = '<leader>/' }
  }
}

local scroll = {
  "karb94/neoscroll.nvim",
  opts = {},
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
--[[
local wakatime = {
  "wakatime/vim-wakatime",
  lazy = false,
} ]]

local vimtex = {
  "lervag/vimtex",
  lazy = false, -- we don't want to lazy load VimTeX
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.vimtex_view_method = "zathura"
  end
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

local colorizer = {
  "norcalli/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local colorizer = require("colorizer")

    colorizer.setup({
      "*",
      "!asm",
      "!bin",
    })
  end,
}

local garmin_monkeyc = {
  'bombsimon/garmin-monkeyc.nvim',
  ft = { 'monkeyc', 'jungle' },
  config = function()
    require('garmin-monkeyc').setup({
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
      on_attach = function(client, bufnr)
        if setup_lsp_keymaps then
          setup_lsp_keymaps(client, bufnr)
        end
      end,
      type_check_level = 'Default',
      optimization_level = 'Default',
      function_completion = 'snippet',
      developer_key = "~/.garmin/developer_key.der",
    })
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
  -- wakatime,
  nvimtree,
  aerial,
  vimtex,
  colorizer,
  garmin_monkeyc,
  -- llama,
  aicmp,
  scroll,
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
  map_key('<leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
    '[W]orkspace [L]ist Folders')

  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_) vim.lsp.buf.format() end,
    { desc = 'Format current buffer with LSP' })
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
      map_key('<leader>td', function() require('telescope.builtin').diagnostics({ bufnr = nil }) end,
        '[T]elescope [D]iagnostics (Errors)')
      vim.keymap.set('v', '<leader>em', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
        { buffer = bufnr, desc = 'LSP: Java: [E]xtract [M]ethod' })
    end
  end,
})

require('lspconfig').nixd.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
})

require('lspconfig').jsonls.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
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

require('lspconfig').ts_ls.setup({
  capabilities = lsp_capabilities,
  on_attach = setup_lsp_keymaps,
})

-- (Keep your existing nvim-cmp, Telescope bindings, and autocmds down here)
-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
-- adding in nix snippets
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
require('luasnip.loaders.from_vscode').lazy_load({ paths = { vim.fn.stdpath 'config' .. '/snippits' } })
require('luasnip.loaders.from_snipmate').lazy_load({ paths = { vim.fn.stdpath 'config' .. '/snippits' } })
require('luasnip.loaders.from_lua').lazy_load({ paths = { vim.fn.stdpath 'config' .. '/snippits' } })
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
