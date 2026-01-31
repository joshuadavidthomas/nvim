vim.filetype.add({
  extension = {
    ebnf = "ebnf",
    hujson = "jsonc",
    njk = "nunjucks",
  },
  pattern = {
    ["%.env[%.%w]*"] = "config",
    [".*%.ya?ml%.tpl$"] = "yaml",
  },
})

vim.treesitter.language.register("twig", "nunjucks")
