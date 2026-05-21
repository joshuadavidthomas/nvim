local M = {}

---@type boolean
local patched_core = false

local html_script_type_languages = {
  importmap = "json",
  module = "javascript",
  ["application/ecmascript"] = "javascript",
  ["text/ecmascript"] = "javascript",
}

local non_filetype_match_injection_language_aliases = {
  ex = "elixir",
  pl = "perl",
  sh = "bash",
  ts = "typescript",
  uxn = "uxntal",
}

---@param captures table<integer, TSNode[]|TSNode|nil>
---@param capture_id integer|string
---@return TSNode|nil
local function get_capture_node(captures, capture_id)
  local capture = captures[capture_id]
  if type(capture) == "table" then
    return capture[1]
  end
  return capture
end

---@param injection_alias string
---@return string
local function get_parser_from_markdown_info_string(injection_alias)
  local match = vim.filetype.match({ filename = "a." .. injection_alias })
  return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
end

local function patch_core_helpers()
  if patched_core or vim.fn.has("nvim-0.12") == 0 then
    return
  end

  patched_core = true

  local treesitter = vim.treesitter
  local original_get_range = treesitter.get_range
  local original_get_node_text = treesitter.get_node_text

  ---@param node TSNode|TSNode[]|nil
  ---@return TSNode|nil
  local function unwrap(node)
    if type(node) == "table" then
      return node[1]
    end
    return node
  end

  treesitter.get_range = function(node, source, metadata)
    local unwrapped = unwrap(node)
    if not unwrapped then
      error("invalid TSNode passed to vim.treesitter.get_range")
    end
    return original_get_range(unwrapped, source, metadata)
  end

  treesitter.get_node_text = function(node, source, opts)
    local unwrapped = unwrap(node)
    if not unwrapped then
      return ""
    end
    return original_get_node_text(unwrapped, source, opts)
  end
end

function M.patch_nvim_treesitter_query_predicates()
  patch_core_helpers()
  if vim.fn.has("nvim-0.12") == 0 then
    return
  end

  local query = require("vim.treesitter.query")
  local opts = { force = true, all = false }

  query.add_directive("set-lang-from-mimetype!", function(captures, _, bufnr, pred, metadata)
    local node = get_capture_node(captures, pred[2])
    if not node then
      return
    end

    local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
    local configured = html_script_type_languages[type_attr_value]
    if configured then
      metadata["injection.language"] = configured
      return
    end

    local parts = vim.split(type_attr_value, "/", {})
    metadata["injection.language"] = parts[#parts]
  end, opts)

  query.add_directive("set-lang-from-info-string!", function(captures, _, bufnr, pred, metadata)
    local node = get_capture_node(captures, pred[2])
    if not node then
      return
    end

    local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
    metadata["injection.language"] = get_parser_from_markdown_info_string(injection_alias)
  end, opts)

  query.add_directive("downcase!", function(captures, _, bufnr, pred, metadata)
    local capture_id = pred[2]
    local node = get_capture_node(captures, capture_id)
    if not node then
      return
    end

    metadata[capture_id] = metadata[capture_id] or {}
    local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[capture_id] }) or ""
    metadata[capture_id].text = string.lower(text)
  end, opts)

  query.add_predicate("nth?", function(captures, _, _, pred)
    local node = get_capture_node(captures, pred[2])
    local n = tonumber(pred[3])
    if node and n and node:parent() and node:parent():named_child_count() > n then
      return node:parent():named_child(n) == node
    end

    return false
  end, opts)

  query.add_predicate("is?", function(captures, _, bufnr, pred)
    local node = get_capture_node(captures, pred[2])
    local types = { unpack(pred, 3) }
    if not node then
      return true
    end

    local locals = require("nvim-treesitter.locals")
    local _, _, kind = locals.find_definition(node, bufnr)
    return vim.tbl_contains(types, kind)
  end, opts)

  query.add_predicate("kind-eq?", function(captures, _, _, pred)
    local node = get_capture_node(captures, pred[2])
    local types = { unpack(pred, 3) }
    if not node then
      return true
    end

    return vim.tbl_contains(types, node:type())
  end, opts)
end

return M
