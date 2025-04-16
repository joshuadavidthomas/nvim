local icons = require("utils.icons")

local function launch_with_args_prompt()
  local dap = require("dap")
  local Snacks = require("snacks")

  local configurations = dap.configurations[vim.bo.filetype]
  if not configurations or #configurations == 0 then
    vim.notify("No DAP configurations found for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end

  local base_config = vim.deepcopy(configurations[1])
  local initial_args_obj = base_config.args or {}
  local initial_args_str = ""
  if type(initial_args_obj) == "function" then
    initial_args_obj = initial_args_obj() or {}
  end
  if type(initial_args_obj) == "table" then
    initial_args_str = table.concat(initial_args_obj, " ")
  elseif type(initial_args_obj) == "string" then
    initial_args_str = initial_args_obj
  end

  Snacks.input({
    prompt = "Run with args: ",
    default = initial_args_str,
  }, function(value)
    if value == nil then
      vim.notify("DAP run cancelled.", vim.log.levels.INFO)
      return
    end

    -- Ensure modules are available in callback scope
    local dap_cb = require("dap")
    local dap_utils_cb = require("dap.utils")

    local new_args_str = vim.fn.expand(value)
    local final_args

    if base_config.type and base_config.type == "java" then
      final_args = new_args_str
    else
      final_args = dap_utils_cb.splitstr(new_args_str)
    end

    local run_config = vim.deepcopy(base_config)
    run_config.args = final_args
    dap_cb.run(run_config)
  end)
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },
    --stylua: ignore
    keys = {
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition", },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>da", function() launch_with_args_prompt() end, desc = "Run with Args", },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "DAP: Toggle UI" },
    },
    config = function()
      -- load mason-nvim-dap here, after all adapters have been setup
      require("mason-nvim-dap").setup(require("utils.plugins").opts("mason-nvim-dap.nvim"))

      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define("Dap" .. name, { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] })
      end

      -- setup dap config by VsCode launch.json file
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end

      local dap = require("dap")
      local dapui = require("dapui")

      --stylua: ignore
      local dap_keymaps = {
        { mode = "n", lhs = "<leader>dC", rhs = function() dap.run_to_cursor() end, desc = "DAP: Run to Cursor" },
        { mode = "n", lhs = "<leader>dg", rhs = function() dap.goto_() end, desc = "DAP: Go to Line" },
        { mode = "n", lhs = "<leader>di", rhs = function() dap.step_into() end, desc = "DAP: Step Into" },
        { mode = "n", lhs = "<leader>dj", rhs = function() dap.down() end, desc = "DAP: Down" },
        { mode = "n", lhs = "<leader>dk", rhs = function() dap.up() end, desc = "DAP: Up" },
        { mode = "n", lhs = "<leader>dU", rhs = function() dap.step_out() end, desc = "DAP: Step Out" },
        { mode = "n", lhs = "<leader>dn", rhs = function() dap.step_over() end, desc = "DAP: Step Over" },
        { mode = "n", lhs = "<leader>dP", rhs = function() dap.pause() end, desc = "DAP: Pause" },
        { mode = "n", lhs = "<leader>dr", rhs = function() dap.repl.toggle() end, desc = "DAP: Toggle REPL" },
        { mode = "n", lhs = "<leader>ds", rhs = function() dap.session() end, desc = "DAP: Session Info" }, -- Maybe adjust desc
        { mode = "n", lhs = "<leader>dq", rhs = function() dap.terminate() end, desc = "DAP: Terminate" },
        { mode = "n", lhs = "<leader>dw", rhs = function() require("dap.ui.widgets").hover() end, desc = "DAP: Widgets Hover" },
        { mode = {"n", "v"}, lhs = "<leader>de", rhs = function() dapui.eval() end, desc = "DAP: Eval" },
      }

      local function set_dap_keymaps()
        if vim.g.dap_keymaps_active then
          return
        end
        for _, map in ipairs(dap_keymaps) do
          vim.keymap.set(map.mode, map.lhs, map.rhs, { desc = map.desc, silent = true })
        end
        vim.g.dap_keymaps_active = true
      end

      local function clear_dap_keymaps()
        if not vim.g.dap_keymaps_active then
          return
        end
        for _, map in ipairs(dap_keymaps) do
          -- vim.keymap.del requires separate calls for each mode if a list was used
          local modes = type(map.mode) == "string" and { map.mode } or map.mode
          for _, m in ipairs(modes) do
            vim.keymap.del(m, map.lhs)
          end
        end
        vim.g.dap_keymaps_active = false
      end

      local listener_key = "dap-keymaps"

      dap.listeners.after.event_initialized[listener_key] = set_dap_keymaps
      dap.listeners.after.event_continued[listener_key] = set_dap_keymaps -- Might need this if session pauses/resumes

      dap.listeners.before.event_terminated[listener_key] = clear_dap_keymaps
      dap.listeners.before.event_exited[listener_key] = clear_dap_keymaps

      vim.g.dap_keymaps_active = false
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {},
    },
    config = function() end,
  },
}
