vim.filetype.add({
  extension = {
    ebnf = "ebnf",
    hujson = "jsonc",
    mdsvex = "mdsvex",
    mdx = "mdx",
    njk = "nunjucks",
    svx = "mdsvex",
  },
  pattern = {
    ["%.env[%.%w]*"] = "config",
    ["%.dev[%.%w]*%.vars[%.%w]*"] = "config",
    [".*%.ya?ml%.tpl$"] = "yaml",
  },
})

vim.treesitter.language.register("twig", "nunjucks")
vim.treesitter.language.register("markdown", { "mdx", "mdsvex" })
