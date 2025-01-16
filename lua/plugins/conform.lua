local p = require("utils.path")

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters = {
      biome = {
        require_cwd = true,
      },
      ["markdown-toc"] = {
        condition = function(_, ctx)
          for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
            if line:find("<!%-%- toc %-%->") then
              return true
            end
          end
        end,
      },
      ["markdownlint-cli2"] = {
        args = {
          "--fix",
          "$FILENAME",
          "--config",
          p.platformdirs().home .. "/.markdownlint-cli2.yaml",
        },
        condition = function(_, ctx)
          local diag = vim.tbl_filter(function(d)
            return d.source == "markdownlint"
          end, vim.diagnostic.get(ctx.buf))
          return #diag > 0
        end,
      },
    },
    formatters_by_ft = {
      astro = { "biome" },
      css = { "biome" },
      graphql = { "biome" },
      htmldjango = { "djlint" },
      javascript = { "biome" },
      javascriptreact = { "biome" },
      json = { "biome" },
      jsonc = { "biome" },
      lua = { "stylua" },
      markdown = { "markdownlint-cli2", "markdown-toc" },
      ["markdown.mdx"] = { "markdownlint-cli2", "markdown-toc" },
      python = { "ruff_fix", "ruff_format" },
      svelte = { "biome" },
      typescript = { "biome" },
      typescriptreact = { "biome" },
      typst = { "typstyle" },
      vue = { "biome" },
    },
  },
}
