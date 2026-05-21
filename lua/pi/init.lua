local M = {}

---@class pi.Config
---@field width number|string floating window width (number for columns, string for percentage)
---@field height number|string floating window height
local defaults = {
  width = 80,
  height = 30,
}

---@type pi.Config
M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  require("pi.colors").setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      require("pi.colors").setup()
    end,
  })

  vim.api.nvim_create_user_command("Pi", function()
    M.toggle()
  end, { desc = "Toggle pi chat" })

  vim.api.nvim_create_user_command("PiAsk", function(cmd)
    M.ask(cmd.args ~= "" and cmd.args or nil)
  end, { nargs = "?", desc = "Ask pi about context" })
end

function M.toggle()
  local ui = require("pi.ui")
  if ui.is_open() then
    ui.close()
  else
    ui.open(M.config)
  end
end

--- Ask pi about the current context (cursor position, visual selection, etc.)
--- If `prompt` is given, sends it immediately. Otherwise opens the chat with
--- context pre-filled in the input.
---@param prompt? string
function M.ask(prompt)
  local context = require("pi.context")
  local ui = require("pi.ui")

  local ctx = context.gather()

  if not ui.is_open() then
    ui.open(M.config)
  end

  local prefix = ctx.description
  if prompt then
    ui.send(prefix .. " — " .. prompt)
  else
    ui.set_input(prefix .. " — ")
  end
end

--- Send a message to the agent and display the response.
---@param message string
function M.send(message)
  local ui = require("pi.ui")
  local agent = require("pi.agent")

  ui.append_message("user", message)

  agent.send(message, function(response)
    vim.schedule(function()
      ui.append_message("assistant", response)
    end)
  end)
end

return M
