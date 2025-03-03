local M = {}

M.lazyfile_event = { "BufReadPost", "BufNewFile", "BufWritePre" }

function M.add_lazyfile_event()
  local Event = require("lazy.core.handler.event")

  Event.mappings.LazyFile = {
    id = "LazyFile",
    event = M.lazyfile_event,
  }
  Event.mappings["User LazyFile"] = Event.mappings.LazyFile
end

function M.verylazy_autocmd(name, callback)
  local group = vim.api.nvim_create_augroup("lazy-" .. name, { clear = true })
  vim.notify("lazy-" .. name)
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    callback = callback,
  })
end

return M
