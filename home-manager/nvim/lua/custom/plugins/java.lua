return {
  'mfussenegger/nvim-jdtls',
  dependencies = {
    'mfussenegger/nvim-dap',
    'neovim/nvim-lspconfig',
  },
  config = function()
    local dap_status, dap = pcall(require, 'dap')
    if dap_status then
      -- Default Java DAP configurations: Launch current file or Attach to running JVM
      dap.configurations.java = {
        {
          type = 'java',
          request = 'launch',
          name = 'Launch Java Program (Current File)',
        },
        {
          type = 'java',
          request = 'attach',
          name = 'Attach to Remote JVM (Port 5005)',
          hostName = '127.0.0.1',
          port = 5005,
        },
        {
          type = 'java',
          request = 'attach',
          name = 'Attach to Remote JVM (Prompt Port)',
          hostName = function()
            return vim.fn.input('Host [127.0.0.1]: ', '127.0.0.1')
          end,
          port = function()
            return tonumber(vim.fn.input('Port [5005]: ', '5005'))
          end,
        },
      }
    end

    -- Locate java-debug plugin jar
    local bundles = {}
    local jar_patterns = {
      vim.fn.stdpath('config') .. '/javadebug/com.microsoft.java.debug.plugin-*.jar',
      '/home/ss-pro/nixos/home-manager/nvim/javadebug/com.microsoft.java.debug.plugin-*.jar',
    }

    for _, pattern in ipairs(jar_patterns) do
      local matched = vim.fn.glob(pattern, 1)
      if matched and matched ~= '' then
        table.insert(bundles, matched)
        break
      end
    end

    -- Setup client capabilities with nvim-cmp support
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local cmp_status, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
    if cmp_status then
      capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
    end

    -- Setup jdtls through lspconfig
    require('lspconfig').jdtls.setup({
      capabilities = capabilities,
      settings = {
        java = {
          completion = {
            favoriteStaticMembers = {
              'edu.wpi.first.units.Units.*',
              'edu.wpi.first.wpilibj.SmartDashboard.*',
              'edu.wpi.first.wpilibj.util.Color.*',
              'org.junit.jupiter.api.Assertions.*',
              'org.mockito.Mockito.*',
            },
          },
        },
      },
      init_options = {
        bundles = bundles,
      },
      on_attach = function(client, bufnr)
        local function map_key(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
        end

        -- Standard LSP keymaps for Java buffers
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
        map_key('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')

        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
          vim.lsp.buf.format()
        end, { desc = 'Format current buffer with LSP' })

        -- JDTLS & DAP integrations
        local jdtls_status, jdtls = pcall(require, 'jdtls')
        if jdtls_status then
          if dap_status then
            -- 1. Register DAP adapter & dynamic config provider
            jdtls.setup_dap({ hotcodereplace = 'auto' })

            -- 2. Populate dap.configurations.java with discovered main classes
            pcall(function()
              require('jdtls.dap').setup_dap_main_class_configs()
            end)

            -- 3. Command to manually trigger main class re-scan
            vim.api.nvim_buf_create_user_command(bufnr, 'JdtUpdateDebugConfig', function()
              require('jdtls.dap').setup_dap_main_class_configs({ verbose = true })
            end, { desc = 'Java: Re-scan main classes for DAP' })
          end

          -- JDTLS code actions and helpers
          map_key('<leader>oi', jdtls.organize_imports, 'Java: [O]rganize [I]mports')
          map_key('<leader>ev', jdtls.extract_variable, 'Java: [E]xtract [V]ariable')
          map_key('<leader>ec', jdtls.extract_constant, 'Java: [E]xtract [C]onstant')
          map_key('<leader>bld', '<CMD>JdtCompile full<CR>', 'Java: [B]ui[ld] Project')
          map_key('<leader>td', function()
            require('telescope.builtin').diagnostics({ bufnr = nil })
          end, '[T]elescope [D]iagnostics (Errors)')
          vim.keymap.set('v', '<leader>em', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], {
            buffer = bufnr,
            desc = 'LSP: Java: [E]xtract [M]ethod',
          })

          -- Test runners
          map_key('<leader>tc', jdtls.test_class, 'Java: [T]est [C]lass')
          map_key('<leader>tm', jdtls.test_nearest_method, 'Java: [T]est Nearest [M]ethod')
        end
      end,
    })
  end,
}
