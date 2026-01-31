return {
  "axkirillov/unified.nvim",
  opts = {},
  keys = {
    {
      "<leader>gu",
      function()
        -- Toggle gitsigns off, disable inlay hints, and show unified diff
        require("gitsigns").toggle_signs(false)
        vim.lsp.inlay_hint.enable(false)
        require("unified.diff").show_current()
      end,
      desc = "Unified diff (HEAD)",
    },
    {
      "<leader>gU",
      function()
        -- Toggle gitsigns off, disable inlay hints, and show unified diff against base branch
        require("gitsigns").toggle_signs(false)
        vim.lsp.inlay_hint.enable(false)
        local default_branch = require("utils.git").get_default_branch(vim.fn.getcwd())
        if default_branch then
          require("unified.diff").show_current(default_branch)
        else
          require("unified.diff").show_current()
        end
      end,
      desc = "Unified diff (base branch)",
    },
    {
      "<leader>gr",
      function()
        -- Reset unified diff, turn gitsigns back on, and re-enable inlay hints
        vim.cmd("Unified reset")
        require("gitsigns").toggle_signs(true)
        vim.lsp.inlay_hint.enable(true)
      end,
      desc = "Reset unified diff",
    },
  },
}
