local function augroup(name)
  return vim.api.nvim_create_augroup("josh-" .. name, { clear = true })
end

-- highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight-yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize-splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto-create-dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close-with-q"),
  pattern = {
    "checkhealth",
    "help",
    "lspinfo",
    "notify",
    "qf",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- when opening HTML file check if in Django project and set filetype automatically
vim.api.nvim_create_autocmd(require("utils.lazy").lazyfile_event, {
  group = augroup("django-filetype-detection"),
  pattern = "*.html",
  callback = function(args)
    local file_dir = vim.fn.fnamemodify(args.file, ":p:h")
    if require("utils.projects").is_project("django", file_dir) then
      vim.bo[args.buf].filetype = "htmldjango"
      return
    end

    vim.bo[args.buf].filetype = "html"
  end,
})

-- Create a mapping of template engines to filetypes
local template_engine_to_filetype = {
  njk = "nunjucks",
  liquid = "liquid",
  hbs = "handlebars",
  handlebars = "handlebars",
  mustache = "mustache",
  ejs = "ejs",
  haml = "haml",
  pug = "pug",
  -- Add more mappings as needed
}

-- 11ty HTML file detection
vim.api.nvim_create_autocmd(require("utils.lazy").lazyfile_event, {
  group = augroup("11ty-html-detection"),
  pattern = "*.html",
  callback = function(args)
    local file_dir = vim.fn.fnamemodify(args.file, ":p:h")
    local is_11ty, metadata = require("utils.projects").is_project("11ty", file_dir)

    if is_11ty and metadata then
      local engine = metadata.html or "njk"
      local filetype = template_engine_to_filetype[engine] or "html"
      vim.bo[args.buf].filetype = filetype
      return
    end

    -- Not an 11ty project, continue with normal HTML filetype
    vim.bo[args.buf].filetype = "html"
  end,
})

-- 11ty Markdown file detection
vim.api.nvim_create_autocmd(require("utils.lazy").lazyfile_event, {
  group = augroup("11ty-markdown-detection"),
  pattern = "*.md",
  callback = function(args)
    local file_dir = vim.fn.fnamemodify(args.file, ":p:h")
    local is_11ty, metadata = require("utils.projects").is_project("11ty", file_dir)

    if is_11ty and metadata then
      -- For markdown, we might want to use a combined filetype
      local engine = metadata.markdown or "njk"
      local template_filetype = template_engine_to_filetype[engine] or "html"

      -- Set a composite filetype if your editor supports it
      vim.bo[args.buf].filetype = template_filetype
      return
    end

    -- Not an 11ty project, continue with normal Markdown filetype
    vim.bo[args.buf].filetype = "markdown"
  end,
})
