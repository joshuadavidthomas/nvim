return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local extensions = {
        "oil",
      }
      for _, extension in ipairs(extensions) do
        table.insert(opts.extensions, extension)
      end
    end,
  },
  {
    "folke/twilight.nvim",
    cmd = "ZenMode",
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      -- plugins = {
      --   gitsigns = { enabled = true },
      --   tmux = { enabled = true },
      -- },
      on_open = function(_)
        vim.o.laststatus = 0
        vim.fn.system([[tmux set status off]])
        vim.fn.system([[tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z]])
      end,
      on_close = function(_)
        vim.o.laststatus = 3
        vim.fn.system([[tmux set status on]])
        vim.fn.system([[tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z]])
      end,
    },
    keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
  },
}
