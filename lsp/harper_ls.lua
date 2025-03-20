---@type vim.lsp.Config
return {
  cmd = { "harper-ls", "--stdio" },
  filetypes = {
    "c",
    "cmake",
    "cpp",
    "cs",
    "dart",
    "gitcommit",
    "go",
    "haskell",
    "html",
    "java",
    "javascript",
    "lua",
    "markdown",
    "nix",
    "php",
    "python",
    "ruby",
    "rust",
    "swift",
    "toml",
    "typescript",
    "typescriptreact",
    "typst",
  },
  on_attach = function(_, bufnr)
    require("snacks")
      .toggle({
        name = "Grammar Checker",
        get = function()
          return not vim.g.harper_ls_disable
        end,
        set = function(state)
          vim.g.harper_ls_disable = not state

          if state then
            require("lsp.servers").enable("harper_ls", bufnr)
          else
            require("lsp.servers").disable("harper_ls", bufnr)
          end
        end,
      })
      :map("<leader>ug")
  end,
  root_markers = {
    ".git",
  },
  settings = {
    codeActions = {
      ForceStable = false,
    },
    diagnosticSeverity = "hint",
    fileDictPath = "",
    isolateEnglish = false,
    linters = {
      AnA = true,
      CorrectNumberSuffix = true,
      LongSentences = true,
      Matcher = true,
      RepeatedWords = true,
      SentenceCapitalization = false,
      Spaces = true,
      SpellCheck = false,
      SpelledNumbers = false,
      UnclosedQuotes = true,
      WrongQuotes = false,
    },
    markdown = {
      IgnoreLinkTitle = false,
    },
    userDictPath = "",
  },
  single_file_support = true,
}
