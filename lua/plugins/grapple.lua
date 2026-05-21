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
      { "<leader>t", group = "+tags" },
    })
  end,
  opts = {
    scope = "git", -- also try out "git_branch"
  },
  config = function(_, opts)
    local validate = vim.validate

    vim.validate = function(...)
      if select("#", ...) == 1 then
        local spec = ...
        if type(spec) == "table" then
          local args = {}
          for name, validator in pairs(spec) do
            vim.list_extend(args, { name, validator[1], validator[2], validator[3] })
          end
          return validate(unpack(args))
        end
      end

      return validate(...)
    end

    local ok, err = pcall(function()
      require("grapple").setup(opts)
    end)
    vim.validate = validate

    if not ok then
      error(err)
    end
  end,
  keys = {
    { "<leader>tt", "<cmd>Grapple toggle<cr>", desc = "Toggle file tag" },
    { "<leader>tl", "<cmd>Grapple toggle_tags<cr>", desc = "List all tags" },
    { "<leader>tL", "<cmd>Grapple toggle_scopes<cr>", desc = "List all scopes" },
    { "<leader>t]", "<cmd>Grapple cycle forward<cr>", desc = "Move forward in tag list" },
    { "<leader>t[", "<cmd>Grapple cycle backward<cr>", desc = "Move backward in tag list" },
    { "<leader>t1", "<cmd>Grapple select index=1<cr>", desc = "select tag 1" },
    { "<leader>t2", "<cmd>Grapple select index=2<cr>", desc = "select tag 2" },
    { "<leader>t3", "<cmd>Grapple select index=3<cr>", desc = "select tag 3" },
    { "<leader>t4", "<cmd>Grapple select index=4<cr>", desc = "select tag 4" },
  },
}
