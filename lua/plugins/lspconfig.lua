return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "saghen/blink.cmp",
    { "j-hui/fidget.nvim", opts = {} },
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
        text = function()
          local icons = require("utils.icons")

          return {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
          }
        end,
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
    servers = {
      lua_ls = {},
    },
  },
  config = function(_, opts)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local buffer = args.buf ---@type number
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
          local Keys = require("lazy.core.handler.keys")
          local lsp_keymaps = require("lsp.keymaps")

          local keymaps = lsp_keymaps.resolve(buffer)

          for _, keys in pairs(keymaps) do
            local has = not keys.has or lsp_keymaps.has(buffer, keys.has)
            local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))

            if has and cond then
              local opts = Keys.opts(keys)
              opts.cond = nil
              opts.has = nil
              opts.silent = opts.silent ~= false
              opts.buffer = buffer
              vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
            end
          end
        end
      end,
    })

    local ensure_installed = {} ---@type string[]
    for server, _ in pairs(opts.servers) do
      table.insert(ensure_installed, server)
    end
    ensure_installed = require("utils").dedupe(ensure_installed)

    require("mason-lspconfig").setup({
      automatic_installation = true,
      ensure_installed = ensure_installed,
      handlers = {
        function(server)
          local config = opts.servers[server] or {}
          local capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for ts_ls)
          config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
          require("lspconfig")[server].setup(config)
        end,
      },
    })
  end,
}
