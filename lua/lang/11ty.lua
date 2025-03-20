local M = {}

M.template_engine_to_filetype = {
  njk = "nunjucks",
  liquid = "liquid",
  hbs = "handlebars",
  handlebars = "handlebars",
  mustache = "mustache",
  ejs = "ejs",
  haml = "haml",
  pug = "pug",
}

-- Detect the template engines used in an Eleventy project
-- @param config_path string Path to the Eleventy config file
-- @return table Template engines configuration
function M.detect_eleventy_template_engines(config_path)
  local content = vim.fn.readfile(config_path)
  local engines = {
    html = "njk", -- Default to njk for HTML
    markdown = "njk", -- Default to njk for Markdown
  }

  for _, line in ipairs(content) do
    -- Look for htmlTemplateEngine setting
    local html_engine = line:match("htmlTemplateEngine%s*:%s*[\"']([^\"']+)[\"']")
    if html_engine then
      engines.html = html_engine
    end

    -- Look for markdownTemplateEngine setting
    local md_engine = line:match("markdownTemplateEngine%s*:%s*[\"']([^\"']+)[\"']")
    if md_engine then
      engines.markdown = md_engine
    end
  end

  return engines
end

---Set up treesitter injections for 11ty template engines in markdown files
---@param bufnr number Buffer number
---@param engine string Template engine name
function M.setup_11ty_injections(bufnr, engine)
  -- Map of template engines to treesitter language names
  local engine_to_lang = {
    njk = "nunjucks",
    liquid = "liquid",
    hbs = "handlebars",
    handlebars = "handlebars",
    mustache = "mustache",
    ejs = "ejs",
    haml = "haml",
    pug = "pug",
  }

  local lang = engine_to_lang[engine] or engine

  -- Only proceed if we have a valid language mapping
  if not lang then
    return
  end

  -- Ensure the parser is available
  local parser_ok, _ = pcall(vim.treesitter.language.add, lang)
  if not parser_ok then
    vim.notify("Treesitter parser for " .. lang .. " not available", vim.log.levels.WARN)
    return
  end

  -- Create a custom injection query for markdown files with template language
  local query = string.format(
    [[
    ;; Inject template language into fenced code blocks with matching language
    ((fenced_code_block
      (info_string) @_lang
      (code_fence_content) @injection.content)
     (#eq? @_lang "%s")
     (#set! injection.language "%s"))

    ;; Inject template language into template tags
    ((inline) @injection.content
     (#lua-match? @injection.content "{[%%{#]")
     (#set! injection.language "%s"))

    ;; Handle front matter
    ((front_matter) @injection.content
     (#set! injection.language "yaml")
     (#offset! @injection.content 1 0 -1 0)
     (#set! injection.include-children))
  ]],
    lang,
    lang,
    lang
  )

  -- Register the query with treesitter
  vim.treesitter.query.set("markdown", "injections-" .. bufnr, query)

  -- Store the query in a buffer variable so it persists
  vim.b[bufnr].eleventy_injection_query = query

  -- Force treesitter to reparse the buffer
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("TSBufEnable highlight")
  end)
end

return M
