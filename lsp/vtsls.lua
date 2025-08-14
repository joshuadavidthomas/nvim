---@type vim.lsp.Config
return {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
    javascript = {},
  },
  single_file_support = true,
  keys = {
    {
      "gD",
      function()
        local params = require("lsp.actions").make_position_params()
        require("lsp.actions").execute({
          command = "typescript.goToSourceDefinition",
          arguments = { params.textDocument.uri, params.position },
          open = true,
        })
      end,
      desc = "Goto Source Definition",
    },
    {
      "gR",
      function()
        require("lsp.actions").execute({
          command = "typescript.findAllFileReferences",
          arguments = { vim.uri_from_bufnr(0) },
          open = true,
        })
      end,
      desc = "File References",
    },
    {
      "<leader>co",
      require("lsp.actions").action["source.organizeImports"],
      desc = "Organize Imports",
    },
    {
      "<leader>cM",
      require("lsp.actions").action["source.addMissingImports"],
      desc = "Add missing imports",
    },
    {
      "<leader>cu",
      require("lsp.actions").action["source.removeUnused"],
      desc = "Remove unused imports",
    },
    {
      "<leader>cD",
      require("lsp.actions").action["source.fixAll"],
      desc = "Fix all diagnostics",
    },
    {
      "<leader>cV",
      function()
        require("lsp.actions").execute({ command = "typescript.selectTypeScriptVersion" })
      end,
      desc = "Select TS workspace version",
    },
  },
  ---@param client vim.lsp.Client
  ---@param _ integer bufnr
  on_attach = function(client, _)
    -- Handle organize imports notification
    client.commands["_typescript.didOrganizeImports"] = function() end

    -- Move to file refactoring
    ---@param command lsp.Command
    ---@param _ lsp.HandlerContext
    client.commands["_typescript.moveToFileRefactoring"] = function(command, _)
      if not command.arguments or #command.arguments < 3 then
        return
      end

      local action = command.arguments[1] --[[@as string]]
      local uri = command.arguments[2] --[[@as string]]
      local range = command.arguments[3] --[[@as lsp.Range]]

      ---@param newf string
      local function move(newf)
        client:request("workspace/executeCommand", {
          command = command.command,
          arguments = { action, uri, range, newf },
        })
      end

      local fname = vim.uri_to_fname(uri)
      client:request("workspace/executeCommand", {
        command = "typescript.tsserverRequest",
        arguments = {
          "getMoveToRefactoringFileSuggestions",
          {
            file = fname,
            startLine = range.start.line + 1,
            startOffset = range.start.character + 1,
            endLine = range["end"].line + 1,
            endOffset = range["end"].character + 1,
          },
        },
      }, function(_, result)
        ---@cast _ lsp.ResponseError|nil
        ---@cast result {body: {files: string[]}}|nil
        if not result or not result.body or not result.body.files then
          return
        end
        ---@type string[]
        local files = result.body.files
        table.insert(files, 1, "Enter new path...")
        vim.ui.select(files, {
          prompt = "Select move destination:",
          format_item = function(f)
            return vim.fn.fnamemodify(f, ":~:.")
          end,
        }, function(f)
          if f and f:find("^Enter new path") then
            vim.ui.input({
              prompt = "Enter move destination:",
              default = vim.fn.fnamemodify(fname, ":h") .. "/",
              completion = "file",
            }, function(newf)
              return newf and move(newf)
            end)
          elseif f then
            move(f)
          end
        end)
      end)
    end
  end,
  ---@param client vim.lsp.Client
  ---@param _ lsp.InitializeResult
  on_init = function(client, _)
    -- Copy typescript settings to javascript
    -- stylua: ignore
    client.config.settings.javascript = vim.tbl_deep_extend(
      "force",
      {},
      client.config.settings.typescript,
      client.config.settings.javascript or {}
    )
  end,
}
