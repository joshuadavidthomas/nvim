local git = require("utils.git")

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

-- if in git repo with github.com origin, add ability to copy permalink
vim.api.nvim_create_autocmd({ "BufEnter", "VimEnter" }, {
  group = augroup("permalink"),
  callback = function()
    local buffer_path = vim.fn.expand("%:p")

    if git.is_in_git_repo(buffer_path) then
      require("which-key").register({
        ["<leader>gl"] = {
          function()
            vim.fn.setreg("+", git.gh_permalink(buffer_path))
            vim.notify("Copied permalink to clipboard")
          end,
          "Copy GH permalink to file",
        },
      }, { mode = "n", buffer = vim.api.nvim_get_current_buf() })
      require("which-key").register({
        ["<leader>gl"] = {
          function()
            vim.fn.setreg("+", git.gh_permalink_lineno(buffer_path))
            vim.api.nvim_input("<Esc>")
            vim.notify("Copied permalink to clipboard")
          end,
          "Copy GH permalink to selection",
        },
      }, { mode = "v", buffer = vim.api.nvim_get_current_buf() })
    end
  end,
})
