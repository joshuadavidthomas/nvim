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
            local tw = require("lang.tailwind")
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
      -- Which Vim modes to enable autopairs in
      modes = { insert = true, command = true, terminal = false },

      -- Skip autopair when next character is one of these (prevents adding pairs before certain characters)
      -- Pattern matches alphanumeric chars, percent, single quote, opening square bracket, double quote, dot, backtick, dollar
      -- Example: typing '(' before 'w' will only insert '(', not '()'
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],

      -- Skip autopair when the cursor is inside these treesitter syntax nodes
      -- Common values: "string", "comment", "parameter", "variable", etc.
      -- Can be checked with :lua print(vim.inspect(vim.treesitter.get_captures_at_cursor(0)))
      skip_ts = { "string" },

      -- Skip autopair when next character is closing pair and there are more closing pairs than opening pairs
      -- Helps avoid situations like: (|) typing ( would result in ((|)) without this option
      skip_unbalanced = true,

      -- Special handling for markdown code blocks with backticks
      -- When you type ``` at the start of a line, it will create a code block
      markdown = true,
    },
    config = function(_, opts)
      Snacks.toggle({
        name = "Mini Pairs",
        get = function()
          return not vim.g.minipairs_disable
        end,
        set = function(state)
          vim.g.minipairs_disable = not state
        end,
      }):map("<leader>up")

      local pairs = require("mini.pairs")

      pairs.setup(opts)

      local open = pairs.open
      ---@diagnostic disable-next-line: duplicate-set-field
      pairs.open = function(pair, neigh_pattern)
        -- If we're in command mode and typing something, use default behavior
        -- This uses the original pairs.open function to maintain normal pair completion
        -- when typing in the command line (:) - the ~= "" check ensures we're actually
        -- typing a command and not just in command mode with an empty line
        if vim.fn.getcmdline() ~= "" then
          return open(pair, neigh_pattern)
        end

        -- Opening and closing chars, current line, cursor pos, char before/after cursor
        local opening, closing = pair:sub(1, 1), pair:sub(2, 2)
        local line = vim.api.nvim_get_current_line()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local next = line:sub(cursor[2] + 1, cursor[2] + 1)
        local before = line:sub(1, cursor[2])

        -- Special handling for markdown code blocks
        -- When typing the third backtick (`) at the start of a line in markdown files,
        -- this automatically creates a proper code block with triple backticks and places
        -- the cursor in between for a better markdown editing experience
        -- Example: typing ``` will result in:
        -- ```
        -- | (cursor here)
        -- ```
        if opts.markdown and opening == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
          return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
        end

        -- Skip auto-closing when next character is in the skip_next pattern
        -- This prevents adding closing pairs when typing in front of certain characters,
        -- which is useful when you want to insert an opening character before something
        -- without automatically adding its pair. For example, when typing "(" before "word"
        -- you probably just want "(word" rather than "(word)".
        -- The next ~= "" check ensures we only apply this when there's actually a character after the cursor
        if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
          return opening
        end

        -- Skip auto-closing when inside specific treesitter syntax nodes
        -- This uses treesitter's syntax awareness to prevent auto-pairing in contexts
        -- where it's usually not wanted, like inside strings or comments
        -- When inside a "string" node, for example, typing a quote usually indicates
        -- you want to escape a quote, not add a new pair of quotes
        -- The pcall protects against errors if treesitter is not available or fails
        if opts.skip_ts and #opts.skip_ts > 0 then
          local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
          for _, capture in ipairs(ok and captures or {}) do
            if vim.tbl_contains(opts.skip_ts, capture.capture) then
              return opening
            end
          end
        end

        -- Skip auto-closing when it would create unbalanced pairs
        -- This is important when typing an opening character right before its matching closing one
        -- For example, with cursor at | in "(|)", typing ( would result in "((|))" without this check,
        -- but with this check it would result in "(|)" because we detect the line already has more
        -- closing brackets than opening ones
        -- The closing ~= opening check excludes identical pairs like '' or "" from this logic
        if opts.skip_unbalanced and next == closing and closing ~= opening then
          local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
          local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
          if count_close > count_open then
            return opening
          end
        end

        -- Default behavior: add both opening and closing characters
        -- If none of the skip conditions above apply, we use the original mini.pairs
        -- open function which inserts both characters of the pair and places
        -- the cursor between them (e.g., typing "(" inserts "()" with cursor between)
        return open(pair, neigh_pattern)
      end
    end,
  },
  -- Neovim Lua plugin with fast and feature-rich surround actions.
  {
    "echasnovski/mini.surround",
    event = "LazyFile",
    opts = {},
  },
}
