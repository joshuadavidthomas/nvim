return {
  "folke/flash.nvim",
  event = "LazyFile",
  ---@type Flash.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    modes = {
      char = {
        jump_labels = true,
      },
    },
  },
  config = function()
    -- always set toggle false when leaving command mode, which allows
    -- for toggling flash on when in search mode, but not persisting it
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      callback = function()
        require("flash").toggle(false)
      end,
    })
  end,
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
