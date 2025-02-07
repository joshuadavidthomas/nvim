return {
  "gbprod/yanky.nvim",
  event = "LazyFile",
  opts = {
    highlight = { timer = 150 },
  },
  keys = {
    {
      "<leader>p",
      function()
        local snacks = require("snacks")
        local picker = snacks.picker

        picker.pick("yank_history", {
          title = "Yank History",
          -- Set the preview to use the item's `preview` data
          preview = "preview",
          finder = function(opts, ctx)
            local items = {}
            local history = require("yanky.history").all()
            local input = ctx.filter.pattern or ""

            for index, entry in ipairs(history) do
              local content = entry.regcontents or ""
              -- Filter items based on the input pattern (case-insensitive)
              if input == "" or content:lower():find(input:lower(), 1, true) then
                items[#items + 1] = {
                  text = content:gsub("\n", "\\n"),
                  idx = index,
                  regtype = entry.regtype,
                  item = entry,
                  -- Provide the preview data directly
                  preview = {
                    text = content,
                    ft = entry.filetype or "", -- Use the yank's filetype if available
                  },
                  pos = { 1, 0 },
                }
              end
            end

            return ctx.filter:filter(items)
          end,
          format = function(item, picker)
            -- Define how each item is displayed in the list
            return {
              { tostring(item.idx) .. ": ", "Comment" },
              { item.text },
            }
          end,
          actions = {
            ["default"] = function(picker)
              local selection = picker:get_selection()
              if selection and selection.item then
                vim.fn.setreg('"', selection.item.regcontents, selection.item.regtype)
                vim.notify("Yank content set to unnamed register", vim.log.levels.INFO)
              end
              picker:close()
            end,
          },
          layout = {
            layout = {
              box = "horizontal",
              width = 0.8,
              min_width = 120,
              height = 0.8,
              {
                box = "vertical",
                border = "rounded",
                title = "{title} {live} {flags}",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
              { win = "preview", title = "{preview}", border = "rounded", width = 0.75 },
            },
          },
        })
      end,
      mode = { "n", "x" },
      desc = "Open Yank History",
    },
    {
      "<leader>P",
      function()
        vim.cmd([[YankyRingHistory]])
      end,
      mode = { "n", "x" },
      desc = "Open Yank History",
    },

        -- stylua: ignore
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Text After Selection" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Selection" },
    { "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
    { "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
    { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
    { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
    { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
    { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
    { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
    { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
    { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
    { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },
    { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying a Filter" },
    { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put Before Applying a Filter" },
  },
}
