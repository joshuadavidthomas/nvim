Util = require("lazyvim.util")

return {
  -- Git related plugins
  {
    "tpope/vim-fugitive",
    event = "LazyFile",
  },
  {
    "tpope/vim-rhubarb",
    event = "LazyFile",
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        map("n", "<leader>gp", gs.preview_hunk, "[p]review git hunk")
        map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "[s]tage Hunk")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "[r]eset Hunk")
        map("n", "<leader>gS", gs.stage_buffer, "[S]tage buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "[u]ndo stage hunk")
        map("n", "<leader>gR", gs.reset_buffer, "[R]eset buffer")
      end,
    },
  },
  {
    "akinsho/toggleterm.nvim",
    event = "VeryLazy",
    version = "*",
    keys = {
      {
        "<leader>gg",
        function()
          local lazygit_cmd = (function()
            -- check if the cwd is $HOME
            -- if so the command should be lazygit --git-dir=$HOME/.local/share/yadm/repo.git --work-tree=$HOME
            -- to account for yadm bare repo
            -- taken from https://github.com/jesseduffield/lazygit/discussions/1201
            -- TODO: revisit this to maybe allow for editing any of the files tracked by yadm
            -- (not sure if this is possible, it probably is but I'm too lazy to figure it out atm)
            if Util.root.cwd() == os.getenv("HOME") then
              return "lazygit --git-dir=$HOME/.local/share/yadm/repo.git --work-tree=$HOME"
            else
              return "lazygit"
            end
          end)()

          require("toggleterm.terminal").Terminal
            :new({
              cmd = lazygit_cmd,
              dir = "git_dir",
              hidden = true,
              direction = "float",
              float_opts = {
                border = "curved",
                winblend = 3,
              },
            })
            :toggle()
        end,
        mode = { "n", "t" },
        desc = "lazy[g]it",
      },
    },
    opts = {
      shading_factor = "-10",
      close_on_exit = true, -- close the terminal window when the process exits
      size = function(term)
        if term.direction == "horizontal" then
          return vim.o.lines * 0.4
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    },
  },
}
