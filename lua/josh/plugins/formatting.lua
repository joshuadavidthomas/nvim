local Util = require("lazyvim.util")

return {
  -- formatter
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = {
          ensure_installed = {
            "shfmt",
            "stylua",
          },
        },
      },
    },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "[f]ormat buffer",
      },
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" } })
        end,
        mode = { "n", "v" },
        desc = "[F]ormat Injected Langs",
      },
      {
        "<leader>cc", "<cmd>ConformInfo<cr>", desc = "[c]onform info",
      },
    },
    init = function()
      -- Install the conform formatter on VeryLazy
      require("lazyvim.util").on_very_lazy(function()
        require("lazyvim.util").format.register({
          name = "conform.nvim",
          priority = 100,
          primary = true,
          format = function(buf)
            local plugin = require("lazy.core.config").plugins["conform.nvim"]
            local Plugin = require("lazy.core.plugin")
            local opts = Plugin.values(plugin, "opts", false)
            require("conform").format(Util.merge(opts.format, { bufnr = buf }))
          end,
          sources = function(buf)
            local ret = require("conform").list_formatters(buf)
            ---@param v conform.FormatterInfo
            return vim.tbl_map(function(v)
              return v.name
            end, ret)
          end,
        })
      end)
    end,
    opts = {
      -- These options will be passed to conform.format()
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
      },
    },
  },
}
