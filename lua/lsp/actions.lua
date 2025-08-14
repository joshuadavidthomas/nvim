local M = {}

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---Execute an LSP command with optional quickfix integration
---@param opts LspCommand
---@return table<integer, integer>|nil client_request_ids Table of client_id:request_id pairs
---@return function|nil err_function Function to check if any client failed
function M.execute(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }

  if opts.open then
    -- Custom handler that opens results in quickfix
    ---@param err lsp.ResponseError|nil
    ---@param result any
    ---@param _ lsp.HandlerContext
    local handler = function(err, result, _)
      if err then
        vim.notify("Error: " .. err.message, vim.log.levels.ERROR)
        return
      end

      if not result then
        return
      end

      -- Handle results
      if type(result) == "table" then
        ---@type (lsp.Location|lsp.LocationLink)[]
        local locations = {}
        if result.uri or result.targetUri then
          -- Single location
          locations = { result }
        elseif #result > 0 and (result[1].uri or result[1].targetUri) then
          -- Multiple locations
          locations = result
        end

        if #locations == 1 then
          -- Jump directly to single result
          local client = vim.lsp.get_clients({ bufnr = 0 })[1]
          local encoding = client and client.offset_encoding or "utf-8"
          vim.lsp.util.show_document(locations[1], encoding, { focus = true })
        elseif #locations > 1 then
          -- Multiple results - show in quickfix
          local client = vim.lsp.get_clients({ bufnr = 0 })[1]
          local encoding = client and client.offset_encoding or "utf-8"
          local items = vim.lsp.util.locations_to_items(locations, encoding)
          vim.fn.setqflist({}, " ", {
            title = opts.command or "LSP Command Results",
            items = items,
          })
          require("quicker").open({ focus = true })
        end
      end
    end

    return vim.lsp.buf_request(0, "workspace/executeCommand", params, handler)
  else
    return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
  end
end

---Create code action functions on demand
---@type table<string, fun()>
M.action = setmetatable({}, {
  ---@param _ table
  ---@param action string
  ---@return function
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action } --[[@as table]],
          diagnostics = {},
        },
      })
    end
  end,
})

---Helper to get position params with proper encoding
---@return lsp.TextDocumentPositionParams
function M.make_position_params()
  local client = vim.lsp.get_clients({ bufnr = 0 })[1]
  local encoding = client and client.offset_encoding or "utf-8"
  return vim.lsp.util.make_position_params(0, encoding)
end

return M
