local M = {}

--- Send a message to the pi agent and invoke the callback with the response.
--- This is a stub — replace with actual pi agent communication.
---@param message string
---@param on_response fun(response: string)
function M.send(message, on_response)
  -- TODO: integrate with pi coding agent
  -- Options to explore:
  --   1. Spawn `pi` as a subprocess via vim.system / jobstart
  --   2. Communicate over a socket/pipe if pi exposes one
  --   3. Use pi's SDK if it has a programmatic API
  --
  -- For now, echo back the message so the UI loop works end-to-end.
  on_response("(stub) received: " .. message)
end

return M
