-- remap jk and kj to <Esc> to exit insert mode
-- additionally move cursor to the right, since by default it is moved to the left, which is hella annoying
local function exit_insert_mode_smartly()
  local col = vim.fn.col(".") -- Get the current cursor column
  local key = col > 1 and "<Esc>l" or "<Esc>"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", false)
end
vim.keymap.set("i", "jk", exit_insert_mode_smartly, { silent = true, noremap = true })
vim.keymap.set("i", "kj", exit_insert_mode_smartly, { silent = true, noremap = true })
vim.keymap.set("i", "<Esc>", exit_insert_mode_smartly, { silent = true, noremap = true })

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- remap <C-u> and <C-d> to center the page automatically
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Page Up" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Page Down" })

-- move lines
vim.keymap.set("n", "<A-J>", "<cmd>m .+1<cr>==", { desc = "Move down" })
vim.keymap.set("n", "<A-K>", "<cmd>m .-2<cr>==", { desc = "Move up" })
vim.keymap.set("i", "<A-J>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
vim.keymap.set("i", "<A-K>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
vim.keymap.set("v", "<A-J>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
vim.keymap.set("v", "<A-K>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- yank an entire buffer
vim.keymap.set("n", "yY", ":%y<cr>", { desc = "Yank buffer" })

-- windows
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- quit
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- lazy
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- format
vim.keymap.set("n", "<leader>cf", function()
  require("utils.format").format()
end, { desc = "Format Document" })
Snacks.toggle({
  name = "Format on Save (Project)",
  get = function()
    return require("utils.format").projects.get()
  end,
  set = function(enabled)
    require("utils.format").projects.set(enabled)
  end,
}):map("<leader>uf")

-- commenting
vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
Snacks.toggle.diagnostics():map("<leader>ud")

-- word wrap
Snacks.toggle.option("wrap", { name = "Word Wrap" }):map("<leader>uW")

-- cursor movement in Wezterm
if require("utils.term").is_wezterm then
  local nav = {
    h = "Left",
    j = "Down",
    k = "Up",
    l = "Right",
  }

  local function navigate(dir)
    return function()
      local win = vim.api.nvim_get_current_win()
      vim.cmd.wincmd(dir)
      local pane = vim.env.WEZTERM_PANE
      if pane and win == vim.api.nvim_get_current_win() then
        local pane_dir = nav[dir]
        vim.system({ "wezterm", "cli", "activate-pane-direction", pane_dir }, { text = true }, function(p)
          if p.code ~= 0 then
            vim.notify("Failed to move to pane " .. pane_dir .. "\n" .. p.stderr, vim.log.levels.ERROR, { title = "Wezterm" })
          end
        end)
      end
    end
  end

  require("utils.term").set_user_var("IS_NVIM", true)

  -- Move to window using the movement keys
  for key, dir in pairs(nav) do
    vim.keymap.set("n", "<" .. dir .. ">", navigate(key))
    vim.keymap.set("n", "<C-" .. key .. ">", navigate(key))
  end
end

-- notes
vim.keymap.set("n", "<leader>nn", function()
  require("utils.notes").toggle_notes_sidebar()
end, { desc = "Toggle Notes" })

-- examine/explore
vim.keymap.set("n", "<leader>xq", function()
  require("quicker").toggle({ focus = true })
end, { desc = "Toggle quickfix" })

-- Treesitter InspectTree toggle panel on the right
do
  local TSInspect = { winid = nil, bufnr = nil }

  local function find_tsinspect_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.b[buf] and vim.b[buf].ts_inspect then
        return win, buf
      end
    end
  end

  local function close_tsinspect()
    local win = TSInspect.winid
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
    TSInspect.winid = nil
    TSInspect.bufnr = nil
  end

  local function open_tsinspect()
    if not (vim.treesitter and vim.treesitter.inspect_tree) then
      vim.notify("InspectTree not available in this Neovim", vim.log.levels.ERROR)
      return
    end

    local before = {}
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      before[w] = true
    end

    local src_win = vim.api.nvim_get_current_win()

    vim.treesitter.inspect_tree({
      command = "rightbelow 60vnew",
      title = function(src_bufnr)
        local name = vim.api.nvim_buf_get_name(src_bufnr)
        name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
        return "Treesitter Syntax Tree • " .. name
      end,
    })

    local new_win
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if not before[w] then
        new_win = w
        break
      end
    end

    if new_win then
      TSInspect.winid = new_win
      TSInspect.bufnr = vim.api.nvim_win_get_buf(new_win)
      vim.b[TSInspect.bufnr].ts_inspect = true
      if vim.api.nvim_win_is_valid(src_win) then
        pcall(vim.api.nvim_set_current_win, src_win)
      end
    end
  end

  local function toggle_tsinspect()
    local win, buf = find_tsinspect_win()
    if win then
      TSInspect.winid = win
      TSInspect.bufnr = buf
      close_tsinspect()
    else
      open_tsinspect()
    end
  end

  vim.keymap.set("n", "<leader>cT", toggle_tsinspect, { desc = "Show TS Tree" })
  vim.api.nvim_create_user_command("InspectTreeToggle", toggle_tsinspect, { desc = "Toggle Treesitter InspectTree panel" })
end
