local M = {}

---@class pi.Context
---@field type "function"|"variable"|"class"|"selection"|"line"|"file"
---@field name string human-readable name of the context target
---@field text string the actual source text
---@field filepath string absolute path to the file
---@field range {start_row: number, start_col: number, end_row: number, end_col: number}|nil
---@field description string one-line summary for the input prompt

--- Get the visual selection text and range.
---@return string text, {start_row: number, start_col: number, end_row: number, end_col: number} range
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then
    return "", { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col }
  end

  -- Trim to selection boundaries
  if #lines == 1 then
    lines[1] = lines[1]:sub(start_col, end_col)
  else
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
  end

  return table.concat(lines, "\n"), { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col }
end

--- Walk up the tree-sitter tree from the cursor to find the nearest
--- named node of a useful type (function, class, variable declaration).
---@return TSNode|nil node, string|nil type
local function find_enclosing_node()
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    return nil, nil
  end

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return nil, nil
  end

  local interesting_types = {
    -- Common across languages
    ["function_declaration"] = "function",
    ["function_definition"] = "function",
    ["method_declaration"] = "function",
    ["method_definition"] = "function",
    ["arrow_function"] = "function",
    ["function_item"] = "function", -- Rust
    ["class_declaration"] = "class",
    ["class_definition"] = "class",
    ["impl_item"] = "class", -- Rust
    ["struct_item"] = "class", -- Rust
    ["variable_declaration"] = "variable",
    ["variable_declarator"] = "variable",
    ["let_declaration"] = "variable", -- Rust
    ["assignment_statement"] = "variable",
  }

  local current = node
  while current do
    local node_type = current:type()
    if interesting_types[node_type] then
      return current, interesting_types[node_type]
    end
    current = current:parent()
  end

  return node, nil
end

--- Get the name of a tree-sitter node (looks for a name/identifier child).
---@param node TSNode
---@return string
local function get_node_name(node)
  for child in node:iter_children() do
    local child_type = child:type()
    if child_type == "identifier" or child_type == "name" or child_type == "property_identifier" then
      return vim.treesitter.get_node_text(child, 0)
    end
  end
  return vim.treesitter.get_node_text(node, 0):sub(1, 40)
end

--- Gather context from the current cursor position or visual selection.
---@return pi.Context
function M.gather()
  local filepath = vim.api.nvim_buf_get_name(0)
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local mode = vim.fn.mode()

  -- Visual selection
  if mode == "v" or mode == "V" or mode == "\22" then
    local text, range = get_visual_selection()
    return {
      type = "selection",
      name = "selection",
      text = text,
      filepath = filepath,
      range = range,
      description = ("[selection in %s:%d-%d]"):format(filename, range.start_row, range.end_row),
    }
  end

  -- Try tree-sitter
  local node, node_kind = find_enclosing_node()
  if node and node_kind then
    local name = get_node_name(node)
    local start_row, start_col, end_row, end_col = node:range()
    local text = vim.treesitter.get_node_text(node, 0)
    return {
      type = node_kind,
      name = name,
      text = text,
      filepath = filepath,
      range = { start_row = start_row + 1, start_col = start_col, end_row = end_row + 1, end_col = end_col },
      description = ("[%s `%s` in %s:%d]"):format(node_kind, name, filename, start_row + 1),
    }
  end

  -- Fallback: current line
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  return {
    type = "line",
    name = "line " .. row,
    text = line,
    filepath = filepath,
    range = { start_row = row, start_col = 0, end_row = row, end_col = #line },
    description = ("[line %d in %s]"):format(row, filename),
  }
end

return M
