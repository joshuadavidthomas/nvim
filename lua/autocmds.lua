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
    "query",
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

vim.api.nvim_create_autocmd(require("utils.lazy").lazyfile_event, {
  group = augroup("html-filetype-detection"),
  pattern = "*.html",
  callback = function(args)
    local lang = require("lang")

    local file_dir = vim.fn.fnamemodify(args.file, ":p:h")

    local is_django = lang.is_project("django", file_dir)
    local is_11ty, metadata = lang.is_project("11ty", file_dir)

    if is_django then
      vim.bo[args.buf].filetype = "htmldjango"
      return
    end

    if is_11ty and metadata then
      local engine = metadata.html or "njk"
      local filetype = require("lang.11ty").template_engine_to_filetype[engine] or "html"
      vim.bo[args.buf].filetype = filetype
      return
    end

    vim.bo[args.buf].filetype = "html"
  end,
})

vim.api.nvim_create_autocmd(require("utils.lazy").lazyfile_event, {
  group = augroup("markdown-detection"),
  pattern = "*.md",
  callback = function(args)
    local file_dir = vim.fn.fnamemodify(args.file, ":p:h")

    local is_11ty, metadata = require("lang.init").is_project("11ty", file_dir)
    if is_11ty and metadata then
      vim.bo[args.buf].filetype = "markdown"

      local engine = metadata.markdown or "njk"
      vim.b[args.buf].eleventy_template_engine = engine

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("eleventy_md_" .. args.buf, { clear = true }),
        pattern = "markdown",
        once = true,
        callback = function()
          -- Delay slightly to ensure treesitter is initialized
          vim.defer_fn(function()
            require("lang.11ty").setup_11ty_injections(args.buf, engine)
          end, 100)
        end,
      })
      return
    end

    vim.bo[args.buf].filetype = "markdown"
  end,
})
