local function augroup(name)
  return vim.api.nvim_create_augroup("josh_" .. name, { clear = true })
end

-- after lazy update, add lock file to dotfiles repo and push
vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazyClean", "LazyVimStarted" },
  group = augroup("yadm"),
  callback = function()
    vim.defer_fn(function()
      local cwd = vim.fn.stdpath("config")
      local lock_file = "lazy-lock.json"
      local has_yadm = vim.fn.executable("yadm") == 1
      if has_yadm then
        local function update_remote(obj)
          if obj.code == 1 then
            vim.notify("Adding lazy-lock.json to dotfiles repo and pushing", "info", { timeout = 5000 })
            vim.system({ "yadm", "add", lock_file }, { cwd = cwd })
            vim.system({ "yadm", "commit", "-m", "update lazy-lock.json" }, { cwd = cwd })
            vim.system({ "yadm", "push" }, { cwd = cwd })
          end
        end
        vim.system({ "yadm", "diff", "--quiet", "--", lock_file }, { cwd = cwd }, update_remote)
      end
    end, 100)
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "chatgpt-input",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})
