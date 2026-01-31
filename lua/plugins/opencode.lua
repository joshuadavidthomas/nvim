return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {} } },
  },
  config = function()
    vim.g.opencode_opts = {
      auto_reload = true,
      auto_register_cmp_sources = { "opencode", "buffer" },
      input = {
        icon = "󱚣",
        win = {
          title_pos = "left",
          relative = "cursor",
          row = -3,
          col = 0,
        },
      },
    }

    vim.opt.autoread = true
  end,
  keys = {
    {
      "<leader>oA",
      function()
        require("opencode").command("agent_cycle")
      end,
      desc = "Cycle selected agent",
    },
    {
      "<leader>oa",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      desc = "Ask about this",
      mode = { "n", "x" },
    },
    {
      "<leader>o+",
      function()
        require("opencode").prompt("@this")
      end,
      desc = "Add this",
      mode = { "n", "x" },
    },
    {
      "<leader>os",
      function()
        require("opencode").select()
      end,
      desc = "Select prompt",
      mode = { "n", "x" },
    },
    {
      "<leader>ot",
      function()
        require("opencode").toggle()
      end,
      desc = "Toggle embedded opencode",
    },
    {
      "<leader>on",
      function()
        require("opencode").command("session_new")
      end,
      desc = "New session",
    },
    {
      "<leader>oi",
      function()
        require("opencode").command("session_interrupt")
      end,
      desc = "Interrupt session",
    },
    {
      "<leader>oy",
      function()
        require("opencode").command("messages_copy")
      end,
      desc = "Copy last message",
    },
    {
      "<S-C-u>",
      function()
        require("opencode").command("messages_half_page_up")
      end,
      desc = "Messages half page up",
    },
    {
      "<S-C-d>",
      function()
        require("opencode").command("messages_half_page_down")
      end,
      desc = "Messages half page down",
    },
    {
      "<leader>oe",
      function()
        local prompt = require("opencode.config").opts.prompts.explain
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Explain this",
      mode = { "n", "x" },
    },
    {
      "<leader>of",
      function()
        local prompt = require("opencode.config").opts.prompts.fix
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Fix diagnostics",
    },
    {
      "<leader>or",
      function()
        local prompt = require("opencode.config").opts.prompts.review
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Review buffer",
    },
    {
      "<leader>od",
      function()
        local prompt = require("opencode.config").opts.prompts.diff
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Review git diff",
    },
    {
      "<leader>oT",
      function()
        local prompt = require("opencode.config").opts.prompts.test
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Add tests",
      mode = { "n", "x" },
    },
    {
      "<leader>oD",
      function()
        local prompt = require("opencode.config").opts.prompts.document
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Document this",
      mode = { "n", "x" },
    },
    {
      "<leader>oO",
      function()
        local prompt = require("opencode.config").opts.prompts.optimize
        require("opencode").prompt(prompt.prompt, prompt)
      end,
      desc = "Optimize this",
      mode = { "n", "x" },
    },
  },
}
