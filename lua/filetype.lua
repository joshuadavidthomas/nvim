vim.filetype.add({
  extension = {
    ebnf = "ebnf",
    njk = "nunjucks",
  },
  pattern = {
    ["%.env[%.%w]*"] = "config",
  },
})
