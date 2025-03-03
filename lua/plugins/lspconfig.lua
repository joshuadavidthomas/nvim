local icons = require("utils.icons")

return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "saghen/blink.cmp",
    {
      "j-hui/fidget.nvim",
      opts = {
        notification = {
          window = {
            winblend = 0,
          },
        },
      },
    },
  },
  opts = {
    capabilities = {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    },
    diagnostics = {
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
        },
      },
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "●",
        -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
        -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
        -- prefix = "icons",
      },
    },
    inlay_hints = {
      enabled = true,
      exclude = {}, -- filetypes for which you don't want to enable inlay hints
    },
    codelens = {
      enabled = false,
    },
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            workspace = {
              checkThirdParty = false,
            },
            codeLens = {
              enable = true,
            },
            completion = {
              callSnippet = "Replace",
            },
            doc = {
              privateName = { "^_" },
            },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = "Disable",
              semicolon = "Disable",
              arrayIndex = "Disable",
            },
          },
        },
      },
    },
    -- Optional format on save with the LSP instead of conform
    -- format_on_save = {
    --   enabled = false,
    --   timeout_ms = 3000,
    -- },
  },
  config = function(_, opts)
    local lsp = require("lsp")

    lsp.setup(opts)

    -- Extract servers to ensure they're installed
    local ensure_installed = {} ---@type string[]
    for server, _ in pairs(opts.servers) do
      table.insert(ensure_installed, server)
    end
    ensure_installed = require("utils").dedupe(ensure_installed)

    -- Setup mason-lspconfig with a simplified handler
    require("mason-lspconfig").setup({
      automatic_installation = true,
      ensure_installed = ensure_installed,
      handlers = {
        function(server)
          -- Get server-specific config or empty table
          local config = vim.deepcopy(opts.servers[server] or {})
          
          -- Add capabilities from blink
          local capabilities = vim.lsp.protocol.make_client_capabilities()
          local has_blink, blink = pcall(require, "blink.cmp")
          if has_blink then
            capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
          end
          
          -- Merge with any server-specific capabilities
          config.capabilities = vim.tbl_deep_extend("force", capabilities, config.capabilities or {})
          
          -- Setup the server
          require("lspconfig")[server].setup(config)
        end,
      },
    })
  end,
}
