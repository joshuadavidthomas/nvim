-- https://biomejs.dev/internals/language-support/
local biome_supported = {
  "astro",
  "css",
  "graphql",
  -- "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  -- "markdown",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  -- "yaml",
}

return {
  {
    "stevearc/conform.nvim",
    ---@module "conform"
    ---@param opts conform.setupOpts
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(biome_supported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        ---@diagnostic disable-next-line: param-type-mismatch
        table.insert(opts.formatters_by_ft[ft], "biome")
      end

      opts.formatters = opts.formatters or {}
      opts.formatters.biome = {
        args = { "check", "--write", "--stdin-file-path", "$FILENAME" },
        require_cwd = true,
      }
    end,
  },
}
