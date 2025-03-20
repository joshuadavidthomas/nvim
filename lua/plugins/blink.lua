-- Performant, batteries-included completion plugin for Neovim
return {
  "saghen/blink.cmp",
  version = "*",
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "Kaiser-Yang/blink-cmp-git",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  opts_extend = {
    "sources.completion.enabled_providers",
    "sources.default",
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    appearance = {
      -- sets the fallback highlight groups to nvim-cmp's highlight groups
      -- useful for when your theme doesn't support blink.cmp
      -- will be removed in a future release, assuming themes add support
      use_nvim_cmp_as_default = false,
      -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },
    completion = {
      accept = {
        -- experimental auto-brackets support
        auto_brackets = {
          enabled = true,
        },
      },
      menu = {
        draw = {
          components = {
            kind_icon = {
              ellipsis = false,
              text = function(ctx)
                local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                return kind_icon
              end,
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
          },
          treesitter = { "lsp" },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      ghost_text = {
        enabled = true,
      },
    },
    keymap = {
      preset = "enter",
      ["<C-j>"] = { "select_next", "fallback_to_mappings" },
      ["<C-k>"] = { "select_prev", "fallback_to_mappings" },
      ["<C-y>"] = { "select_and_accept" },
    },
    sources = {
      default = { "git", "lsp", "path", "snippets", "buffer", "markdown" },
      providers = {
        git = {
          module = "blink-cmp-git",
          name = "Git",
          enabled = function()
            return vim.tbl_contains({ "octo", "gitcommit", "markdown" }, vim.bo.filetype)
          end,
          opts = {},
        },
        markdown = {
          name = "RenderMarkdown",
          module = "render-markdown.integ.blink",
          fallbacks = { "lsp" },
        },
      },
    },
    cmdline = {
      enabled = false,
    },
  },
  config = function(_, opts)
    require("blink.cmp").setup(opts)

    local lsp_capabilities = require("lsp.capabilities")

    lsp_capabilities.on_dynamic_capability(function(client, _)
      local blink_capabilities = require("blink.cmp").get_lsp_capabilities()
      if client.server_capabilities then
        client.server_capabilities = vim.tbl_deep_extend("force", client.server_capabilities, blink_capabilities)
        return true
      end
    end)

    -- Use the centralized method to trigger capability updates for all clients
    lsp_capabilities.trigger_dynamic_capabilities()
  end,
}
