local Util = require("lazyvim.util")

return {
  -- Fuzzy Finder (files, lsp, etc)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = "make",
        enabled = vim.fn.executable("make") == 1,
        config = function()
          Util.on_load("telescope.nvim", function()
            require("telescope").load_extension("fzf")
          end)
        end,
      },
    },
    -- stylua: ignore
    keys = function()
      local exclude_test_py_files = {
        "fd", "--type", "f", "--exclude", "test_*.py"
      }
      return {
      { "<leader><space>", "<leader>sb", desc = "[ ] Find existing buffers", remap = true },
      { "<leader>/", function() require("telescope.builtin").live_grep() end, desc = "[/] Grep Files" },
      { "<leader>sf", function() require("telescope.builtin").find_files({ hidden = true }) end, desc = "[f]iles" },
      { "<leader>sg", function() require("telescope.builtin").git_files() end, desc = "[g]it files" },
      { "<leader>sb", function() require("telescope.builtin").buffers() end, desc = "[b]uffers" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "[h]elp" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "[k]eymaps" },
      { "<leader>sda", function() require("telescope.builtin").live_grep({ glob_pattern = { "admin.py", "!test_*.py"} }) end, desc = "[a]dmin" },
      { "<leader>sdf", function() require("telescope.builtin").find_files({ search_file = "forms.py", find_command=exclude_test_py_files }) end, desc = "[f]orms" },
      { "<leader>sdm", function() require("telescope.builtin").live_grep({ glob_pattern = { "models.py", "!test_*.py " } }) end, desc = "[m]odels" },
      { "<leader>sdv", function() require("telescope.builtin").find_files({ search_file = "views.py", find_command=exclude_test_py_files }) end, desc = "[v]iews" },
    }
    end,
    opts = function()
      local actions = require("telescope.actions")

      local function flash(prompt_bufnr)
        require("flash").jump({
          pattern = "^",
          label = { after = { 0, 0 } },
          search = {
            mode = "search",
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
              end,
            },
          },
          action = function(match)
            local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        })
      end

      return {
        defaults = {
          mappings = {
            i = {
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
              ["<c-s>"] = flash,
            },
            n = {
              ["s"] = flash,
              ["q"] = actions.close,
            },
          },
        },
      }
    end,
  },
  -- file explorer
  -- {
  --   "nvim-neo-tree/neo-tree.nvim",
  --   branch = "v3.x",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
  --     "MunifTanjim/nui.nvim",
  --     -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  --   },
  --   cmd = "Neotree",
  --   keys = {
  --     {
  --       "<leader>fe",
  --       function()
  --         require("neo-tree.command").execute({ toggle = true, dir = Util.root() })
  --       end,
  --       desc = "File [e]xplorer",
  --     },
  --     { "<leader>e", "<leader>fe", desc = "File [e]xplorer", remap = true },
  --   },
  --   deactivate = function()
  --     vim.cmd([[Neotree close]])
  --   end,
  --   init = function()
  --     if vim.fn.argc(-1) == 1 then
  --       local stat = vim.loop.fs_stat(vim.fn.argv(0))
  --       if stat and stat.type == "directory" then
  --         require("neo-tree")
  --       end
  --     end
  --   end,
  --   opts = {
  --     sources = { "filesystem", "buffers", "git_status", "document_symbols" },
  --     open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
  --     filesystem = {
  --       bind_to_cwd = false,
  --       follow_current_file = { enabled = true },
  --       use_libuv_file_watcher = true,
  --     },
  --     window = {
  --       mappings = {
  --         ["<space>"] = "none",
  --       },
  --     },
  --     default_component_configs = {
  --       indent = {
  --         with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
  --         expander_collapsed = "",
  --         expander_expanded = "",
  --         expander_highlight = "NeoTreeExpander",
  --       },
  --     },
  --   },
  --   config = function(_, opts)
  --     local function on_move(data)
  --       Util.lsp.on_rename(data.source, data.destination)
  --     end
  --     local events = require("neo-tree.events")
  --     opts.event_handlers = opts.event_handlers or {}
  --     vim.list_extend(opts.event_handlers, {
  --       { event = events.FILE_MOVED, handler = on_move },
  --       { event = events.FILE_RENAMED, handler = on_move },
  --     })
  --     require("neo-tree").setup(opts)
  --     vim.api.nvim_create_autocmd("TermClose", {
  --       pattern = "*lazygit",
  --       callback = function()
  --         if package.loaded["neo-tree.sources.git_status"] then
  --           require("neo-tree.sources.git_status").refresh()
  --         end
  --       end,
  --     })
  --   end,
  -- },
  -- mini.files explorer
  {
    "echasnovski/mini.files",
    opts = function()
      local function width_preview(ratio)
        return math.ceil(vim.o.columns * ratio)
      end
      return {
        mappings = {
          close = "",
          go_in_plus = "",
        },
        windows = {
          preview = true,
          width_focus = 30,
          width_preview = width_preview(0.65),
        },
        options = {
          -- Whether to use for editing directories
          -- Disabled by default in LazyVim because neo-tree is used for that
          use_as_default_explorer = false,
        },
      }
    end,
    keys = function()
      local MiniFiles = require("mini.files")
      local function minifiles_toggle(args)
        return function()
          if not MiniFiles.close() then
            MiniFiles.open(unpack(args))
          end
        end
      end
      return {
        { "<leader>e", "<leader>fe", desc = "File [e]xplorer", remap = true },
        {
          "<leader>fe",
          minifiles_toggle({ Util.root(), true }),
          desc = "File [e]xplorer (root)",
        },
        {
          "<leader>ff",
          minifiles_toggle({ vim.api.nvim_buf_get_name(0), true }),
          desc = "File explorer (current [f]ile)",
        },
        {
          "<leader>fc",
          function()
            require("mini.files").open(vim.loop.cwd(), true)
          end,
          desc = "File explorer (current [c]wd)",
        },
      }
    end,
    config = function(_, opts)
      local MiniFiles = require("mini.files")
      MiniFiles.setup(opts)

      local show_dotfiles = true

      local filter_show = function(_)
        return true
      end
      local filter_hide_dotfiles = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide_dotfiles
        MiniFiles.refresh({ content = { filter = new_filter } })
      end

      local go_in_plus = function()
        for _ = 1, vim.v.count1 - 1 do
          MiniFiles.go_in()
        end
        local fs_entry = MiniFiles.get_fs_entry()
        local is_at_file = fs_entry ~= nil and fs_entry.fs_type == "file"
        MiniFiles.go_in()
        if is_at_file then
          MiniFiles.close()
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local map_buf = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.data.buf_id, desc = desc })
          end

          map_buf("g.", toggle_dotfiles, "To[g]gle [.]dotfiles")

          map_buf("L", go_in_plus, "Go in p[L]us")
          map_buf("<CR>", go_in_plus, "Go in p[L]us")

          map_buf("q", MiniFiles.close, "Close")
          map_buf("<Esc>", MiniFiles.close, "Close")
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event)
          require("lazyvim.util").lsp.on_rename(event.data.from, event.data.to)
        end,
      })
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope.nvim",
        config = function()
          require("telescope").setup({
            extensions = {
              file_browser = {
                theme = "ivy",
                grouped = true,
                sorting_strategy = "ascending",
              },
            },
          })
          require("telescope").load_extension("file_browser")
        end,
      },
      "nvim-lua/plenary.nvim",
    },
    keys = {
      {
        "<leader>fb",
        function()
          require("telescope").extensions.file_browser.file_browser({
            path = "%:p:h",
            select_buffer = true,
          })
        end,
        desc = "File [b]rowser",
      },
    },
  },
  -- Displays a popup with possible key bindings of the command you started typing
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = { spelling = true },
      defaults = {
        mode = { "n", "v" },
        ["<leader>b"] = { name = "+[b]uffer" },
        ["<leader>c"] = { name = "+[c]ode" },
        ["<leader>g"] = { name = "+[g]it" },
        ["<leader>f"] = { name = "+[f]ile/[f]ind" },
        ["<leader>s"] = { name = "+[s]earch" },
        ["<leader>sr"] = { name = "+[r]eplace" },
        ["<leader>sd"] = { name = "+[d]jango" },
        ["<leader>u"] = { name = "+[u]i" },
        ["<leader>w"] = { name = "+[w]indow" },
        ["<leader>t"] = { name = "+[t]est" },
        ["<leader>x"] = { name = "+diagnostics/quickfi[x]" },
        ["<leader>q"] = { name = "+[q]uit/session" },
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.register(opts.defaults)
    end,
  },
  -- create and manage predefined window layouts
  -- {
  --   "folke/edgy.nvim",
  --   event = "VeryLazy",
  --   keys = {
  --     {
  --       "<leader>ue",
  --       function()
  --         require("edgy").toggle()
  --       end,
  --       desc = "Edgy Toggle",
  --     },
  --     -- stylua: ignore
  --     { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
  --   },
  --   opts = function()
  --     local opts = {
  --       bottom = {
  --         {
  --           ft = "toggleterm",
  --           size = { height = 0.4 },
  --           filter = function(buf, win)
  --             return vim.api.nvim_win_get_config(win).relative == ""
  --           end,
  --         },
  --         {
  --           ft = "noice",
  --           size = { height = 0.4 },
  --           filter = function(buf, win)
  --             return vim.api.nvim_win_get_config(win).relative == ""
  --           end,
  --         },
  --         {
  --           ft = "lazyterm",
  --           title = "LazyTerm",
  --           size = { height = 0.4 },
  --           filter = function(buf)
  --             return not vim.b[buf].lazyterm_cmd
  --           end,
  --         },
  --         "Trouble",
  --         {
  --           ft = "trouble",
  --           filter = function(buf, win)
  --             return vim.api.nvim_win_get_config(win).relative == ""
  --           end,
  --         },
  --         { ft = "qf", title = "QuickFix" },
  --         {
  --           ft = "help",
  --           size = { height = 20 },
  --           -- don't open help files in edgy that we're editing
  --           filter = function(buf)
  --             return vim.bo[buf].buftype == "help"
  --           end,
  --         },
  --         { title = "Spectre", ft = "spectre_panel", size = { height = 0.4 } },
  --         { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
  --       },
  --       left = {
  --         {
  --           title = "Neo-Tree",
  --           ft = "neo-tree",
  --           filter = function(buf)
  --             return vim.b[buf].neo_tree_source == "filesystem"
  --           end,
  --           pinned = true,
  --           open = function()
  --             vim.api.nvim_input("<esc><space>e")
  --           end,
  --           size = { height = 0.5 },
  --         },
  --         { title = "Neotest Summary", ft = "neotest-summary" },
  --         {
  --           title = "Neo-Tree Git",
  --           ft = "neo-tree",
  --           filter = function(buf)
  --             return vim.b[buf].neo_tree_source == "git_status"
  --           end,
  --           pinned = true,
  --           open = "Neotree position=right git_status",
  --         },
  --         {
  --           title = "Neo-Tree Buffers",
  --           ft = "neo-tree",
  --           filter = function(buf)
  --             return vim.b[buf].neo_tree_source == "buffers"
  --           end,
  --           pinned = true,
  --           open = "Neotree position=top buffers",
  --         },
  --         "neo-tree",
  --       },
  --       keys = {
  --         -- increase width
  --         ["<c-Right>"] = function(win)
  --           win:resize("width", 2)
  --         end,
  --         -- decrease width
  --         ["<c-Left>"] = function(win)
  --           win:resize("width", -2)
  --         end,
  --         -- increase height
  --         ["<c-Up>"] = function(win)
  --           win:resize("height", 2)
  --         end,
  --         -- decrease height
  --         ["<c-Down>"] = function(win)
  --           win:resize("height", -2)
  --         end,
  --       },
  --     }
  --     return opts
  --   end,
  -- },
  -- buffer remove
  {
    "echasnovski/mini.bufremove",
    keys = {
      {
        "<leader>bd",
        function()
          local bd = require("mini.bufremove").delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = "[d]elete buffer",
      },
      -- stylua: ignore
      { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "[D]elete buffer (force)" },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    event = "VeryLazy",
    version = "*",
    keys = {
      { "<esc><esc>", "<c-\\><c-n>", mode = "t", desc = "Enter Normal Mode" },
      {
        "<c-/>",
        "<cmd>ToggleTerm<CR>",
        mode = { "n", "t" },
        desc = "ToggleTerm (horizontal)",
      },
      {
        "<c-_>",
        "<cmd>ToggleTerm<CR>",
        mode = { "n", "t" },
        desc = "which_key_ignore",
      },
    },
    opts = {
      shading_factor = "-10",
      close_on_exit = true, -- close the terminal window when the process exits
      size = function(term)
        if term.direction == "horizontal" then
          return vim.o.lines * 0.4
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    },
  },
  -- Flash enhances the built-in search functionality by showing labels
  -- at the end of each match, letting you quickly jump to a specific
  -- location.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ss",
        mode = { "n", "o", "x" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "<leader>sS",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "<leader>sr",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "<leader>sR",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },
  -- Automatically highlights other instances of the word under your cursor.
  -- This works with LSP, Treesitter, and regexp matching to find the other
  -- instances.
  {
    "RRethy/vim-illuminate",
    event = "LazyFile",
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)

      local function map(key, dir, buffer)
        vim.keymap.set("n", key, function()
          require("illuminate")["goto_" .. dir .. "_reference"](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", buffer = buffer })
      end

      map("]]", "next")
      map("[[", "prev")

      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map("]]", "next", buffer)
          map("[[", "prev", buffer)
        end,
      })
    end,
    keys = {
      { "]]", desc = "Next Reference" },
      { "[[", desc = "Prev Reference" },
    },
  },
  -- better diagnostics list and others
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    opts = { use_diagnostic_signs = true },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "[x] Document Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "[X] Workspace Diagnostics (Trouble)" },
      { "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "[L]ocation List (Trouble)" },
      { "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "[Q]uickfix List (Trouble)" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").previous({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Previous trouble/quickfix item",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Next trouble/quickfix item",
      },
    },
    -- Finds and lists all of the TODO, HACK, BUG, etc comment
    -- in your project and loads them into a browsable list.
    {
      "folke/todo-comments.nvim",
      cmd = { "TodoTrouble", "TodoTelescope" },
      event = "LazyFile",
      config = true,
      keys = {
        {
          "]t",
          function()
            require("todo-comments").jump_next()
          end,
          desc = "Next todo comment",
        },
        {
          "[t",
          function()
            require("todo-comments").jump_prev()
          end,
          desc = "Previous todo comment",
        },
        { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "[t]odo (Trouble)" },
        { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "All [T]odo/Fix/Fixme (Trouble)" },
        { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "[t]odo" },
        { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "All [T]odo/Fix/Fixme" },
      },
    },
  },
  -- search/replace in multiple files
  {
    "nvim-pack/nvim-spectre",
    build = false,
    cmd = "Spectre",
    opts = {
      open_cmd = "noswapfile vnew",
    },
    -- stylua: ignore
    keys = {
      { "<leader>srr", function() require("spectre").toggle() end, desc = "[r] all files" },
      { "<leader>srf", function() require("spectre").open_file_search() end, desc = "current [f]ile" },
      { "<leader>srF", function() require("spectre").open_file_search({ select_word=true }) end, desc = "current word in [F]ile" },
      { "<leader>srw", function() require("spectre").open_visual({ select_word=true }) end, desc = "current [w]ord", mode = "n" },
      { "<leader>srw", function() require("spectre").open_visual() end, desc = "current [w]ord", mode = "v" },
    },
  },
}
