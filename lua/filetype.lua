local dj = require("utils.django")

-- when opening HTML file check if in Django project and set filetype automatically
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.html",
  callback = function(args)
    if dj.is_django_project(vim.fn.fnamemodify(args.file, ":p:h")) then
      vim.bo[args.buf].filetype = "htmldjango"
      return
    end

    vim.bo[args.buf].filetype = "html"
  end,
  group = vim.api.nvim_create_augroup("DjangoFiletypeDetection", { clear = true }),
  desc = "Set filetype for Django HTML templates",
})

vim.filetype.add({
  extension = {
    ebnf = "ebnf",
    dhtml = "htmldjango",
    djhtml = "htmldjango",
  },
  pattern = {
    ["%.env[%.%w]*"] = "config",
  },
})
