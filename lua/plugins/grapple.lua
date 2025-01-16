return {
  "cbochs/grapple.nvim",
  event = "LazyFile",
  cmd = "Grapple",
  dependencies = {
    "folke/which-key.nvim",
  },
  init = function()
    local wk = require("which-key")
    wk.add({
      { "<leader>a", group = "+tags" },
    })
  end,
  opts = {
    scope = "git", -- also try out "git_branch"
  },
  keys = {
    { "<leader>at", "<cmd>Grapple toggle<cr>", desc = "[t]oggle file tag" },
    { "<leader>al", "<cmd>Grapple toggle_tags<cr>", desc = "[l]ist all tags" },
    { "<leader>aL", "<cmd>Grapple toggle_scopes<cr>", desc = "[L]ist all scopes" },
    { "<leader>aj", "<cmd>Grapple cycle forward<cr>", desc = "[j] move forward in tag list" },
    { "<leader>ak", "<cmd>Grapple cycle backward<cr>", desc = "[k] move backward in tag list" },
    { "<leader>a1", "<cmd>Grapple select index=1<cr>", desc = "select tag [1]" },
    { "<leader>a2", "<cmd>Grapple select index=2<cr>", desc = "select tag [2]" },
    { "<leader>a3", "<cmd>Grapple select index=3<cr>", desc = "select tag [3]" },
    { "<leader>a4", "<cmd>Grapple select index=4<cr>", desc = "select tag [4]" },
  },
}
