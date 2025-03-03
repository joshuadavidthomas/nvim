local M = {}

---@param opts vim.diagnostic.Opts
function M.setup(opts)
  -- Configure diagnostic signs
  if type(opts.signs) ~= "boolean" and opts.signs.text then
    for severity, icon in pairs(opts.signs.text) do
      local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
      name = "DiagnosticSign" .. name
      vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
    end
  end

  -- Configure virtual text prefix if it's using icons function
  if type(opts.virtual_text) == "table" and opts.virtual_text.prefix == "icons" then
    local icons = require("utils.icons").diagnostics
    opts.virtual_text.prefix = function(diagnostic)
      for d, icon in pairs(icons) do
        if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
          return icon
        end
      end
      return "●" -- Fallback icon
    end
  end

  vim.diagnostic.config(vim.deepcopy(opts))
end

return M
