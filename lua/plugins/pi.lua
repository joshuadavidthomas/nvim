-- pi coding agent integration
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/pi",
    name = "pi.nvim",
    keys = {
      { "<leader>a", group = "agent" },
      {
        "<leader>aa",
        function()
          require("pi").toggle()
        end,
        desc = "Toggle chat",
      },
      {
        "<leader>ak",
        function()
          require("pi").ask()
        end,
        desc = "Ask about context",
        mode = { "n", "v" },
      },
    },
    cmd = { "Pi", "PiAsk" },
    config = function()
      require("pi").setup()
    end,
  },
}
