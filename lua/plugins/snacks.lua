-- A collection of QoL plugins for Neovim
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      profiler = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command
        end,
      })
    end,
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      dashboard = {
        preset = {
          pick = "fzf-lua",
          --         header = [[
          -- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
          -- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
          -- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
          -- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
          -- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
          -- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
          header = [[
 █▄ █ ██▀ ▄▀▄ █ █ █ █▄ ▄█
 █ ▀█ █▄▄ ▀▄▀ ▀▄▀ █ █ ▀ █]],
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "N", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        },
        sections = {
          { section = "header" },
          { section = "keys", padding = 1 },
          { section = "startup" },
        },
        width = 40,
      },
    },
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      picker = { enabled = true },
    },
    -- stylua: ignore
    keys = {
      { "<leader>,",       function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
      { "<leader>/",       function() Snacks.picker.grep() end,                                    desc = "Grep" },
      { "<leader>:",       function() Snacks.picker.command_history() end,                         desc = "Command History" },
      { "<leader><space>", function() Snacks.picker.files() end,                                   desc = "Find Files" },
      -- find
      { "<leader>fb",      function() Snacks.picker.buffers() end,                                 desc = "Buffers" },
      { "<leader>fc",      function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      { "<leader>ff",      function() Snacks.picker.files() end,                                   desc = "Find Files" },
      { "<leader>fF",      function() Snacks.picker.files({ cwd = LazyVim.root() }) end,           desc = "Find Files (cwd)" },
      { "<leader>fg",      function() Snacks.picker.git_files() end,                               desc = "Find Git Files" },
      { "<leader>fG",      function() Snacks.picker.git_files({ cwd = LazyVim.root() }) end,       desc = "Find Git Files" },
      { "<leader>fr",      function() Snacks.picker.recent() end,                                  desc = "Recent" },
      { "<leader>fR",      function() Snacks.picker.recent({ cwd = LazyVim.root() }) end,          desc = "Recent (cwd)" },
      -- git
      -- { "<leader>gd",      function() Snacks.picker.git_diff() end,                                desc = "Git Diff (hunks)" },
      -- { "<leader>gs",      function() Snacks.picker.git_status() end,                              desc = "Git Status" },
      -- Grep
      { "<leader>sb",      function() Snacks.picker.lines() end,                                   desc = "Buffer Lines" },
      { "<leader>sB",      function() Snacks.picker.grep_buffers() end,                            desc = "Grep Open Buffers" },
      { "<leader>sg",      function() Snacks.picker.grep() end,                                    desc = "Grep" },
      { "<leader>sG",      function() Snacks.picker.grep({ cwd = LazyVim.root() }) end,            desc = "Grep (cwd)" },
      { "<leader>sw",      function() Snacks.picker.grep_word() end,                               desc = "Visual selection or word",       mode = { "n", "x" } },
      { "<leader>sW",      function() Snacks.picker.grep_word({ cwd = LazyVim.root() }) end,       desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
      -- search
      { '<leader>s"',      function() Snacks.picker.registers() end,                               desc = "Registers" },
      { "<leader>sa",      function() Snacks.picker.autocmds() end,                                desc = "Autocmds" },
      { "<leader>sc",      function() Snacks.picker.command_history() end,                         desc = "Command History" },
      { "<leader>sC",      function() Snacks.picker.commands() end,                                desc = "Commands" },
      { "<leader>sd",      function() Snacks.picker.diagnostics() end,                             desc = "Diagnostics" },
      { "<leader>sh",      function() Snacks.picker.help() end,                                    desc = "Help Pages" },
      { "<leader>sH",      function() Snacks.picker.highlights() end,                              desc = "Highlights" },
      { "<leader>sj",      function() Snacks.picker.jumps() end,                                   desc = "Jumps" },
      { "<leader>sk",      function() Snacks.picker.keymaps() end,                                 desc = "Keymaps" },
      { "<leader>sl",      function() Snacks.picker.loclist() end,                                 desc = "Location List" },
      { "<leader>sM",      function() Snacks.picker.man() end,                                     desc = "Man Pages" },
      { "<leader>sm",      function() Snacks.picker.marks() end,                                   desc = "Marks" },
      { "<leader>sR",      function() Snacks.picker.resume() end,                                  desc = "Resume" },
      { "<leader>sq",      function() Snacks.picker.qflist() end,                                  desc = "Quickfix List" },
      { "<leader>uC",      function() Snacks.picker.colorschemes() end,                            desc = "Colorschemes" },
      { "<leader>sp",      function() Snacks.picker.projects() end,                                desc = "Projects" },
    },
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      scratch = { enabled = true },
    },
    -- stylua: ignore
    keys = {
      { "<leader>.",       function() Snacks.scratch() end,                                        desc = "Toggle Scratch Buffer" },
      { "<leader>ns",      function() Snacks.scratch.select() end,                                 desc = "Select Scratch Buffer" },
      { "<leader>nt",      function() Snacks.scratch() end,                                        desc = "Toggle Scratch Buffer" },
    },
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      lazygit = { enabled = true },
    },
    -- stylua: ignore
    keys = {
      { "<leader>gg",      function() Snacks.lazygit({ cwd = Snacks.git.get_root() }) end,         desc = "Lazygit" },
      { "<leader>gG",      function() Snacks.lazygit() end,                                        desc = "Lazygit (cwd)" },
      { "<leader>gs",      function() Snacks.lazygit({ args = { "status" }, config = { gui = { showCommandLog = true } } }) end,                 desc = "Status" },
      { "<leader>gl",      function() Snacks.lazygit.log() end,                                    desc = "Git log" },
    },
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      notifier = { enabled = true },
    },
    -- stylua: ignore
    keys = {
      { "<leader>n",       function() Snacks.notifier.show_history() end,                          desc = "Notification History" },
    },
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      toggle = { enabled = true },
    },
    config = function(_, opts)
      local Snacks = require("snacks")
      Snacks.setup(opts)

      Snacks.toggle.line_number():map("<leader>ul")
      Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    end,
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      styles = {
        zen = {
          backdrop = { transparent = true, blend = 25 },
        },
      },
      zen = {},
    },
    -- stylua: ignore
    config = function(_, opts)
      local Snacks = require("snacks")
      Snacks.setup(opts)

      Snacks.toggle.zen():map("<leader>uz")
      Snacks.toggle.zoom():map("<leader>uZ")
    end,
  },
}
