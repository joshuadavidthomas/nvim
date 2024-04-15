return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      local remove_sources = { ["markdown"] = { "prettier" } }
      -- Loop through the filetypes in formatters_by_ft
      for filetype, formatters in pairs(opts.formatters_by_ft) do
        -- Check if the current filetype has formatters to remove
        if remove_sources[filetype] then
          -- Filter out the specified formatters for this filetype
          opts.formatters_by_ft[filetype] = vim.tbl_filter(function(formatter)
            return not vim.tbl_contains(remove_sources[filetype], formatter)
          end, formatters)
        end
      end
      return opts
    end,
  },
}
