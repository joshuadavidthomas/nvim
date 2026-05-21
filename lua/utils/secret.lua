local M = {}

---@return string|nil secret
---@return string|nil error_message
function M.generate()
  local result = vim.system({ "openssl", "rand", "-base64", "32" }, { text = true }):wait()

  if result.code ~= 0 then
    local error_message = result.stderr ~= "" and result.stderr or "openssl rand failed"
    return nil, vim.trim(error_message)
  end

  return vim.trim(result.stdout), nil
end

function M.yank()
  local secret, error_message = M.generate()
  if not secret then
    vim.notify(error_message, vim.log.levels.ERROR, { title = "Secret" })
    return
  end

  vim.fn.setreg("+", secret)
  vim.fn.setreg('"', secret)
  vim.notify("Secret copied to clipboard", vim.log.levels.INFO, { title = "Secret" })
end

return M
