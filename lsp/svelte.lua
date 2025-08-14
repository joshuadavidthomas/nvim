---Organize imports in the current buffer
local function organize_imports()
  -- Use synchronous request to avoid race conditions with formatting
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    context = {
      only = { "source.organizeImports" },
      diagnostics = {},
    },
  }
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
  if result and next(result) then
    for _, res in pairs(result) do
      if res.result and #res.result > 0 then
        vim.lsp.buf.code_action({
          context = {
            only = { "source.organizeImports" },
            diagnostics = {},
          },
          apply = true,
        })
        break
      end
    end
  end
end

---@type vim.lsp.Config
return {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_dir = function(bufnr, on_dir)
    local root_files = { "package.json", ".git" }
    local fname = vim.api.nvim_buf_get_name(bufnr)
    -- Svelte LSP only supports file:// schema. https://github.com/sveltejs/language-tools/issues/2777
    if vim.uv.fs_stat(fname) ~= nil then
      on_dir(vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1]))
    end
  end,
  keys = {
    { "<leader>co", organize_imports, desc = "Organize Imports" },
  },
  ---@param client vim.lsp.Client
  ---@param bufnr integer
  on_attach = function(client, bufnr)
    -- Auto organize imports on save
    local group = vim.api.nvim_create_augroup("svelte_organize_imports_" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      group = group,
      callback = organize_imports,
    })

    -- Workaround to trigger reloading JS/TS files
    -- See https://github.com/sveltejs/language-tools/issues/2008
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      group = vim.api.nvim_create_augroup("svelte_js_ts_file_watch", {}),
      ---@param ctx table
      callback = function(ctx)
        -- internal API to sync changes that have not yet been saved to the file system
        client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
    vim.api.nvim_buf_create_user_command(bufnr, "LspMigrateToSvelte5", function()
      client:exec_cmd({
        title = "Migrate to Svelte 5",
        command = "migrate_to_svelte_5",
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, { desc = "Migrate Component to Svelte 5 Syntax" })

    -- Configure TypeScript plugin for vtsls
    local vtsls_client = vim.lsp.get_clients({ name = "vtsls", bufnr = bufnr })[1]
    if vtsls_client then
      local plugin_path = require("utils.mason").get_pkg_path("svelte-language-server", "node_modules/typescript-svelte-plugin")
      vtsls_client.config.settings = vim.tbl_deep_extend("force", vtsls_client.config.settings or {}, {
        vtsls = {
          tsserver = {
            globalPlugins = {
              {
                name = "typescript-svelte-plugin",
                location = plugin_path,
                enableForWorkspaceTypeScriptVersions = true,
              },
            },
          },
        },
      })
      vtsls_client:notify("workspace/didChangeConfiguration", { settings = vtsls_client.config.settings })
    end
  end,
}
