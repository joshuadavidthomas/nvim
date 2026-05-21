return {
  {
    "ivov/lisette",
    event = "VeryLazy",
    config = function(plugin)
      vim.opt.rtp:append(plugin.dir .. "/editors/nvim")
      dofile(plugin.dir .. "/editors/nvim/ftdetect/lisette.lua")
      dofile(plugin.dir .. "/editors/nvim/plugin/lisette.lua")
    end,
  },
  {
    "echasnovski/mini.icons",
    opts = {
      extension = {
        lis = { glyph = "", hl = "MiniIconsPurple" },
      },
      filetype = {
        lisette = { glyph = "", hl = "MiniIconsPurple" },
      },
    },
  },
}
