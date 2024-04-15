vim.filetype.add({
  pattern = {
    ["%.env[%.%w]*"] = "config",
    ["requirements*.txt$"] = "config",
  },
})
