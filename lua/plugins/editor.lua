return {
  {
    "stevearc/oil.nvim",
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>fo",
        function()
          require("oil").open()
        end,
        desc = "File browser (oil)",
      },
    },
  },
  {
    "chrisgrieser/nvim-early-retirement",
    config = true,
    event = "VeryLazy",
  },
  {
    "cbochs/grapple.nvim",
    opts = {
      scope = "git", -- also try out "git_branch"
    },
    event = "LazyFile",
    cmd = "Grapple",
    keys = {
      { "<leader>at", "<cmd>Grapple toggle<cr>", desc = "[t]oggle file tag" },
      { "<leader>al", "<cmd>Grapple toggle_tags<cr>", desc = "[l]ist all tags" },
      { "<leader>aL", "<cmd>Grapple toggle_scopes<cr>", desc = "[L]ist all scopes" },
      { "<leader>aj", "<cmd>Grapple cycle forward<cr>", desc = "[j] move forward in tag list" },
      { "<leader>ak", "<cmd>Grapple cycle backward<cr>", desc = "[k] move backward in tag list" },
      { "<leader>a1", "<cmd>Grapple select index=1<cr>", desc = "select tag [1]" },
      { "<leader>a2", "<cmd>Grapple select index=2<cr>", desc = "select tag [2]" },
      { "<leader>a3", "<cmd>Grapple select index=3<cr>", desc = "select tag [3]" },
      { "<leader>a4", "<cmd>Grapple select index=4<cr>", desc = "select tag [4]" },
    },
  },
  {
    "mrjones2014/smart-splits.nvim",
    opts = {},
    keys = function()
      local dirkeys = {
        h = "Left",
        j = "Down",
        k = "Up",
        l = "Right",
      }

      local keys = {}

      for key, dir in pairs(dirkeys) do
        local function action(ss_func)
          return require("smart-splits")[ss_func .. "_" .. string.lower(dir)]
        end
        local function desc(init)
          return init .. " " .. string.lower(dir)
        end

        local swap_action = action("swap_buf")
        local swap_desc = desc("Swap pane")

        table.insert(keys, { "<C-" .. key .. ">", action("move_cursor"), mode = "n", desc = desc("Move cursor") })
        table.insert(keys, { "<C-" .. dir .. ">", action("resize"), mode = "n", desc = desc("Resize pane") })
        table.insert(keys, { "<leader><C-" .. dir .. ">", swap_action, mode = "n", desc = swap_desc })
        table.insert(keys, { "<leader><C-" .. key .. ">", swap_action, mode = "n", desc = swap_desc })
      end

      return keys
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
      { "<leader>fr", LazyVim.telescope("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
      { "<leader>fR", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },
}
