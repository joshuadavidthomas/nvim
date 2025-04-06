local M = {}

local function process_colors(colors, prefix, result)
  result = result or {}
  prefix = prefix or ""

  for k, v in pairs(colors) do
    if not k:match("^_") then -- Skip metadata keys that start with underscore
      local key = k:gsub("_", "-") -- Convert underscores to dashes

      if type(v) == "table" then
        process_colors(v, prefix .. key .. "-", result)
      else
        -- Add the color variable
        result[prefix .. key] = v
      end
    end
  end

  return result
end

--- @param colors ColorScheme
function M.generate(colors)
  local theme_name = (colors._name or "theme"):gsub("_", "-") -- Convert underscores to dashes in theme name

  local variables = process_colors(colors, "")

  local css = "@theme {\n"

  local sorted_keys = {}
  for k in pairs(variables) do
    table.insert(sorted_keys, k)
  end
  table.sort(sorted_keys)

  -- Add each variable to the CSS
  for _, k in ipairs(sorted_keys) do
    css = css .. "    --" .. theme_name .. "-" .. k .. ": " .. variables[k] .. ";\n"
  end

  css = css .. "}\n"

  return css
end

function M.setup()
  local tokyonight = require("tokyonight")
  local Util = require("tokyonight.util")

  local styles = {
    storm = " Storm",
    night = "",
    day = " Day",
    moon = " Moon",
  }

  os.execute("mkdir -p dist")

  for style, _ in pairs(styles) do
    local colors, _, _ = tokyonight.load({ style = style, plugins = { all = true } })

    local fname = "tokyonight-" .. style .. ".css"

    print("[write] " .. fname)
    Util.write("dist/" .. fname, M.generate(colors))
  end

  print("CSS files generated successfully in the dist directory.")
end

return M
