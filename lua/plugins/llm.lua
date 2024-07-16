local p = require("josh.utils.path")

return {
  {
    "jackMort/ChatGPT.nvim",
    cmd = { "ChatGPT", "ChatGPTEditWithInstruction", "ChatGPTRun" },
    config = function()
      require("chatgpt").setup({ api_key_cmd = "cat " .. p.platformdirs().home .. "/.chatgpt" })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "folke/trouble.nvim",
      "nvim-telescope/telescope.nvim",
      "folke/which-key.nvim",
    },
    init = function()
      local wk = require("which-key")
      wk.add({
        { "<leader>cp", group = "+chatgpt" },
      })
    end,
    keys = {
      { "<leader>cpc", "<cmd>ChatGPT<CR>", desc = "ChatGPT" },
      { "<leader>cpe", "<cmd>ChatGPTEditWithInstruction<CR>", mode = { "n", "v" }, desc = "Edit with instruction" },
      { "<leader>cpg", "<cmd>ChatGPTRun grammar_correction<CR>", mode = { "n", "v" }, desc = "Grammar Correction" },
      { "<leader>cpt", "<cmd>ChatGPTRun translate<CR>", mode = { "n", "v" }, desc = "Translate" },
      { "<leader>cpk", "<cmd>ChatGPTRun keywords<CR>", mode = { "n", "v" }, desc = "Keywords" },
      { "<leader>cpd", "<cmd>ChatGPTRun docstring<CR>", mode = { "n", "v" }, desc = "Docstring" },
      { "<leader>cpa", "<cmd>ChatGPTRun add_tests<CR>", mode = { "n", "v" }, desc = "Add Tests" },
      { "<leader>cpo", "<cmd>ChatGPTRun optimize_code<CR>", mode = { "n", "v" }, desc = "Optimize Code" },
      { "<leader>cps", "<cmd>ChatGPTRun summarize<CR>", mode = { "n", "v" }, desc = "Summarize" },
      { "<leader>cpf", "<cmd>ChatGPTRun fix_bugs<CR>", mode = { "n", "v" }, desc = "Fix Bugs" },
      { "<leader>cpx", "<cmd>ChatGPTRun explain_code<CR>", mode = { "n", "v" }, desc = "Explain Code" },
      { "<leader>cpr", "<cmd>ChatGPTRun roxygen_edit<CR>", mode = { "n", "v" }, desc = "Roxygen Edit" },
      {
        "<leader>cpl",
        "<cmd>ChatGPTRun code_readability_analysis<CR>",
        mode = { "n", "v" },
        desc = "Code Readability Analysis",
      },
    },
  },
}
