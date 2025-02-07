local M = {}

M.hl = {}

return {
  -- Neovim Lua plugin to extend and create `a`/`i` textobjects.
  {
    "echasnovski/mini.ai",
    event = "LazyFile",
    opts = {},
  },
  {
    "echasnovski/mini.comment",
    event = "LazyFile",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
      opts = {
        enable_autocmd = false,
      },
    },
    opts = {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
  },
  {
    "echasnovski/mini.diff",
    event = "LazyFile",
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      view = {
        style = "sign",
        signs = {
          add = "▎",
          change = "▎",
          delete = "",
        },
      },
    },
    config = function(_, opts)
      require("mini.diff").setup(opts)

      require("snacks")
        .toggle({
          name = "Mini Diff Signs",
          get = function()
            return vim.g.minidiff_disable ~= true
          end,
          set = function(state)
            vim.g.minidiff_disable = not state
            if state then
              require("mini.diff").enable(0)
            else
              require("mini.diff").disable(0)
            end
            -- HACK: redraw to update the signs
            vim.defer_fn(function()
              vim.cmd([[redraw!]])
            end, 200)
          end,
        })
        :map("<leader>uG")
    end,
  },
  -- Highlight patterns in text.
  {
    "echasnovski/mini.hipatterns",
    event = "LazyFile",
    opts = function()
      local hi = require("mini.hipatterns")
      return {
        tailwind = {
          enabled = true,
          ft = {
            "astro",
            "blade",
            "css",
            "heex",
            "html",
            "html-eex",
            "htmldjango",
            "javascript",
            "javascriptreact",
            "rust",
            "svelte",
            "typescript",
            "typescriptreact",
            "vue",
          },
          -- full: the whole css class will be highlighted
          -- compact: only the color will be highlighted
          style = "full",
        },
        highlighters = {
          hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
          shorthand = {
            pattern = "()#%x%x%x()%f[^%x%w]",
            group = function(_, _, data)
              ---@type string
              local match = data.full_match
              local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
              local hex_color = "#" .. r .. r .. g .. g .. b .. b

              return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
            end,
            extmark_opts = { priority = 2000 },
          },
        },
      }
    end,
    config = function(_, opts)
      if type(opts.tailwind) == "table" and opts.tailwind.enabled then
        -- reset hl groups when colorscheme changes
        vim.api.nvim_create_autocmd("ColorScheme", {
          callback = function()
            M.hl = {}
          end,
        })
        opts.highlighters.tailwind = {
          pattern = function()
            if not vim.tbl_contains(opts.tailwind.ft, vim.bo.filetype) then
              return
            end
            if opts.tailwind.style == "full" then
              return "%f[%w:-]()[%w:-]+%-[a-z%-]+%-%d+()%f[^%w:-]"
            elseif opts.tailwind.style == "compact" then
              return "%f[%w:-][%w:-]+%-()[a-z%-]+%-%d+()%f[^%w:-]"
            end
          end,
          group = function(_, _, m)
            local tw = require("utils.tailwind")
            ---@type string
            local match = m.full_match
            ---@type string, number
            local color, shade = match:match("[%w-]+%-([a-z%-]+)%-(%d+)")
            shade = tonumber(shade)
            local bg = vim.tbl_get(tw.colors, color, shade)
            if bg then
              local hl = "MiniHipatternsTailwind" .. color .. shade
              if not M.hl[hl] then
                M.hl[hl] = true
                local bg_shade = shade == 500 and 950 or shade < 500 and 900 or 100
                local fg = vim.tbl_get(tw.colors, color, bg_shade)
                vim.api.nvim_set_hl(0, hl, { bg = "#" .. bg, fg = "#" .. fg })
              end
              return hl
            end
          end,
          extmark_opts = { priority = 2000 },
        }
      end
      require("mini.hipatterns").setup(opts)
    end,
  },
  {
    "echasnovski/mini.icons",
    event = "VeryLazy",
    opts = {},
  },
  -- Neovim Lua plugin to automatically manage character pairs.
  {
    "echasnovski/mini.pairs",
    event = "LazyFile",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
  },
  -- Neovim Lua plugin with fast and feature-rich surround actions.
  {
    "echasnovski/mini.surround",
    event = "LazyFile",
    opts = {},
  },
}
