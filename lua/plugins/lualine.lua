return {
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
}
