return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  cmd = {
    "ObsidianOpen",
    "ObsidianQuickSwitch",
    "ObsidianNew",
    "ObsidianSearch",
    "ObsidianTemplate",
    "ObsidianToday",
    "ObsidianTomorrow",
    "ObsidianYesterday",
  },
  event = {
    "BufReadPre " .. vim.fn.expand("~") .. "/obsidian/**.md",
    "BufNewFile " .. vim.fn.expand("~") .. "/obsidian/**.md",
    "BufReadPre /mnt/c/Users/jthomas/OneDrive - The Westervelt Company/Documents/Obsidian Sync/**.md",
    "BufNewFile /mnt/c/Users/jthomas/OneDrive - The Westervelt Company/Documents/Obsidian Sync/**.md",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter",
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/obsidian/notes",
      },
    },
  },
  -- {
  --   "LintaoAmons/scratch.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "hrsh7th/nvim-cmp",
  --     "nvim-telescope/telescope.nvim",
  --     "nvim-treesitter",
  --     "folke/which-key.nvim",
  --   },
  --   keys = {
  --     { "<leader>nn", "<cmd>Scratch<cr>", desc = "[n]ew scratch buffer" },
  --     { "<leader>no", "<cmd>ScratchOpen<cr>", desc = "[o]pen existing scratch buffer" },
  --   },
  --   config = function()
  --     local wk = require("which-key")
  --     wk.register({
  --       ["n"] = { name = "+notes" },
  --     })
  --   end,
  -- },
  {
    "RutaTang/quicknote.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>nn",
        function()
          require("quicknote").NewNoteAtCurrentLine()
        end,
        desc = "[n]ew note at current line",
      },
      {
        "<leader>no",
        function()
          require("quicknote").OpenNoteAtCurrentLine()
        end,
        desc = "[o]pen note for current line",
      },
      {
        "<leader>nt",
        function()
          require("quicknote").ToggleNoteSigns()
        end,
        desc = "[t]oggle note signs",
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.register({
        ["n"] = { name = "+notes" },
      })
      require("quicknote").setup(opts)
    end,
  },
}
