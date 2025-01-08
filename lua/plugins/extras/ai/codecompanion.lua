local p = require("josh.utils.path")

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>cia", "<cmd>CodeCompanionActions<cr>", desc = "Open action palette", mode = { "n", "v" } },
      { "<leader>cit", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle chat", mode = { "n", "v" } },
      { "<leader>cic", "<cmd>CodeCompanionCmd<cr>", desc = "Open command line" },
      { "<leader>cip", "<cmd>CodeCompanion<cr>", desc = "Open inline assistant" },
      { "<leader>cid", "<cmd>CodeCompanionChat Add<cr>", desc = "Add selection to chat", mode = "v" },
    },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])

      local wk = require("which-key")
      wk.add({
        { "<leader>ci", group = "+a[i] companion" },
      })
    end,
    opts = {
      adapters = {
        anthropic = function()
          local file = p.platformdirs().home .. "/.anthropic"

          local api_key = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file)[1]:gsub("%s+", "")

          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = api_key,
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "anthropic",
        },
        inline = {
          adapter = "anthropic",
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      sources = {
        -- Change the sources to suit your config
        default = { "lsp", "path", "buffer", "codecompanion" },
        providers = {
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
          },
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function(_, opts)
      opts.ft = opts.ft or {}
      table.insert(opts.ft, "codecompanion")
      return opts
    end,
  },
}
