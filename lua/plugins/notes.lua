return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter",
    },
    opts = {
      workspaces = {
        {
          name = "notes",
          path = "~/Documents/notes",
        },
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
        "<leader>nd",
        function()
          require("quicknote").DeleteNoteAtCurrentLine()
        end,
        desc = "[d]elete note for current line",
      },
      {
        "<leader>nt",
        function()
          require("quicknote").ToggleNoteSigns()
        end,
        desc = "[t]oggle note signs",
      },
    },
    init = function()
      local wk = require("which-key")
      wk.add({
        { "<leader>n", group = "+notes" },
      })
    end,
    config = function(_, opts)
      require("quicknote").setup(opts)
    end,
  },
}
