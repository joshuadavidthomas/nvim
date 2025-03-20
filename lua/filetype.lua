vim.filetype.add({
  extension = {
    ebnf = "ebnf",
    njk = "nunjucks",
  },
  pattern = {
    ["%.env[%.%w]*"] = "config",
  },
})

vim.treesitter.language.register("twig", "nunjucks")
