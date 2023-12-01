local Util = require("lazyvim.util")
local map = vim.keymap.set

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- remap jk and kj to <Esc> to exit insert mode
-- additionally move cursor to the right, since by default it is moved to the left, which is hella annoying
-- also adjust the normal <Esc> keymap to move cursor to the right
-- does come with a quirk if you're at the beginning of a line, it will move the cursor to the right
-- but that's a small tradeoff IMO (and there may be a way to adjust this behavior)
map("i", "jk", "<Esc>l")
map("i", "kj", "<Esc>l")
map("i", "<Esc>", "<Esc>l")

-- windows
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
map("n", "<leader>ww", "<C-w>p", { desc = "Other [w]indow", remap = true })
map("n", "<leader>wd", "<C-w>c", { desc = "[d]elete window", remap = true })
map("n", "<leader>w-", "<C-w>s<C-w>j", { desc = "[-] Split window below", remap = true })
map("n", "<leader>w|", "<C-w>v<C-w>l", { desc = "[|] Split window right", remap = true })
map("n", "<leader>-", "<C-w>s<C-w>j", { desc = "[-] Split window below", remap = true })
map("n", "<leader>|", "<C-w>v<C-w>l", { desc = "[|] Split window right", remap = true })
map("n", "<leader>wo", "<C-w>o", { desc = "f[o]cus window", remap = true })
map("n", "<leader>w=", "<C-w>=", { desc = "[=] Equalize windows", remap = true })
map("n", "<leader>ws", "<C-w><C-r><C-w>", { desc = "[s]wap windows", remap = true })

-- Move Lines
-- Yanked from the default LazyVim config and modified to use alt + shift + j/k
-- as just alt + j/k doesn't seem to work in Windows Terminal
map("n", "<A-J>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-K>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<A-J>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<A-K>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<A-J>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-K>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- lazy
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "[l]azy" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New [f]ile" })

-- toggle
-- stylua: ignore
map("n", "<leader>uL", function() Util.toggle("relativenumber") end, { desc = "Toggle relative [L]ine numbers" })
map("n", "<leader>ul", function()
  Util.toggle.number()
end, { desc = "Toggle [l]ine numbers" })
map("n", "<leader>us", function() Util.toggle("spell") end, { desc = "Toggle [s]pell" })
map("n", "<leader>uS", function() Util.toggle("spelllang") end, { desc = "Toggle [S]pell language" })
map("n", "<leader>uW", function() Util.toggle("wrap") end, { desc = "Toggle [W]rap" })
map("n", "<leader>uw", function() Util.toggle("cursorline") end, { desc = "Toggle [w]rap" })
map("n", "<leader>uc", function() Util.toggle("list") end, { desc = "Toggle whitespace [c]haracters" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "[q]uit all" })
