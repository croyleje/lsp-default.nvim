# Lazy loading with lazy.nvim

Lots of you really like this lazy loading business. Let me show you how to defer everything in lsp-default using [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  {
    'croyleje/lsp-default.nvim',
    branch = 'v2.x',
    lazy = true,
    config = function()
      -- This is where you modify the settings for lsp-default
      -- Note: autocompletion settings will not take effect

      require('lsp-default.settings').preset({})
    end
  },

  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {'L3MON4D3/LuaSnip'},
    },
    config = function()
      -- Here is where you configure the autocompletion settings.
      -- The arguments for .extend() have the same shape as `manage_nvim_cmp`:
      -- https://github.com/croyleje/lsp-default.nvim/blob/v2.x/doc/md/api-reference.md#manage_nvim_cmp

      require('lsp-default.cmp').extend()

      -- And you can configure cmp even more, if you want to.
      local cmp = require('cmp')
      local cmp_action = require('lsp-default.cmp').action()

      cmp.setup({
        mapping = {
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-f>'] = cmp_action.luasnip_jump_forward(),
          ['<C-b>'] = cmp_action.luasnip_jump_backward(),
        }
      })
    end
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    cmd = 'LspInfo',
    event = {'BufReadPre', 'BufNewFile'},
    dependencies = {
      {'hrsh7th/cmp-nvim-lsp'},
      {'williamboman/mason-lspconfig.nvim'},
      {'williamboman/mason.nvim'},
    },
    config = function()
      -- This is where all the LSP shenanigans will live

      local lsp = require('lsp-default')

      lsp.on_attach(function(client, bufnr)
        -- see :help lsp-default-keybindings
        -- to learn the available actions
        lsp.default_keymaps({buffer = bufnr})
      end)

      -- (Optional) Configure lua language server for neovim
      require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

      lsp.setup()
    end
  }
}
```
