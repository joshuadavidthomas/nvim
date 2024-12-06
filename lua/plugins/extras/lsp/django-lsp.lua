local p = require("josh.utils.path")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        django_lsp = {},
      },
      setup = {
        django_lsp = function(_, opts)
          local configs = require("lspconfig.configs")
          local util = require("lspconfig.util")

          if not configs.django_lsp then
            configs.django_lsp = {
              default_config = {
                cmd = { p.platformdirs().home .. "/projects/django-language-server/target/debug/djls" },
                filetypes = { "htmldjango" },
                root_dir = function(fname)
                  local root = util.root_pattern("manage.py", "pyproject.toml")(fname)
                  vim.notify("LSP root dir: " .. (root or "nil"))
                  return root or vim.fn.getcwd()
                end,
                handlers = {
                  ["window/logMessage"] = function(_, params, _)
                    local message_type = {
                      [1] = vim.log.levels.ERROR,
                      [2] = vim.log.levels.WARN,
                      [3] = vim.log.levels.INFO,
                      [4] = vim.log.levels.DEBUG,
                    }
                    vim.notify(params.message, message_type[params.type], {
                      title = "Django LSP",
                    })
                  end,
                },
                on_attach = function(client, bufnr)
                  vim.notify("Django LSP attached to buffer: " .. bufnr)
                end,
              },
            }
          end
          require("lspconfig").django_lsp.setup({})
        end,
      },
    },
  },
}
