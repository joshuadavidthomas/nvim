return {
  {
    "supermaven-inc/supermaven-nvim",
    config = true,
    dependencies = {
      {
        "nvim-cmp",
        ---@param opts cmp.ConfigSchema
        opts = function(_, opts)
          table.insert(opts.sources, 1, {
            name = "supermaven",
            group_index = 1,
            priority = 100,
          })
        end,
      },
    },
  },
}
