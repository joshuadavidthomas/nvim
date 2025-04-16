return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    code = {
      left_pad = 2,
    },
    completions = {
      blink = {
        enabled = true,
      },
      lsp = {
        enabled = true,
      },
    },
    heading = {
      sign = false,
      icons = {},
    },
    html = {
      comment = {
        conceal = false,
      },
    },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    Snacks.toggle({
      name = "Render Markdown",
      get = function()
        return require("render-markdown.state").enabled
      end,
      set = function(enabled)
        local m = require("render-markdown")
        if enabled then
          m.enable()
        else
          m.disable()
        end
      end,
    }):map("<leader>um")
  end,
}
