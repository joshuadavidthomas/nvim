local dj = require("josh.utils.django")

vim.notify("Setting up Django filetype detection...")

-- Create an autocommand for HTML files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.html",
  callback = function(args)
    vim.notify("Checking HTML file: " .. args.file)
    
    -- Check if we're in a Django project
    if dj.is_django_project(vim.fn.fnamemodify(args.file, ":p:h")) then
      vim.notify("Django project detected")
      
      -- Check if file is in templates directory
      if args.file:match("templates/.*%.html$") then
        vim.notify("Setting htmldjango filetype")
        vim.bo[args.buf].filetype = "htmldjango"
        return
      end
    end
    
    vim.notify("Setting html filetype")
    vim.bo[args.buf].filetype = "html"
  end,
  group = vim.api.nvim_create_augroup("DjangoFiletypeDetection", { clear = true }),
  desc = "Set filetype for Django HTML templates",
})

-- Keep the .djhtml detection
vim.filetype.add({
  pattern = {
    ["%.env[%.%w]*"] = "config",
    ["requirements.*%.txt$"] = "config",
    ["%.djhtml$"] = "htmldjango",
  },
})

vim.notify("Django filetype detection setup complete")
