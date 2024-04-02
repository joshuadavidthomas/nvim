local map = vim.keymap.set

-- remap jk and kj to <Esc> to exit insert mode
-- additionally move cursor to the right, since by default it is moved to the left, which is hella annoying
local function exit_insert_mode_smartly()
  local col = vim.fn.col(".") -- Get the current cursor column
  local key = col > 1 and "<Esc>l" or "<Esc>"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", false)
end
map("i", "jk", exit_insert_mode_smartly, { silent = true, noremap = true })
map("i", "kj", exit_insert_mode_smartly, { silent = true, noremap = true })
map("i", "<Esc>", exit_insert_mode_smartly, { silent = true, noremap = true })

-- remap <C-u> and <C-d> to center the page automatically
map("n", "<C-u>", "<C-u>zz", { desc = "Page Up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Page Down" })

-- move lines
-- yanked from the default LazyVim config and modified to use alt + shift + j/k
-- as just alt + j/k doesn't seem to work in Windows Terminal
map("n", "<A-J>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-K>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<A-J>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<A-K>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<A-J>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-K>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- copy github permalink
map({ "n", "v" }, "<leader>gl", require("utils.git").copy_gh_permalink, { desc = "Copy GH permalink to file" })
