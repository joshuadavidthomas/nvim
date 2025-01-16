-- copied from `LazyVim/LazyVim`, license included in the `.licenses` directory at the root of the repo

return {
  -- depends on the typescript
  -- just including this to make sure it's noted
  { import = "plugins.lang.typescript" },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        svelte = {
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
          capabilities = {
            workspace = {
              didChangeWatchedFiles = vim.fn.has("nvim-0.10") == 0 and { dynamicRegistration = true },
            },
          },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
        {
          name = "typescript-svelte-plugin",
          location = LazyVim.get_pkg_path("svelte-language-server", "/node_modules/typescript-svelte-plugin"),
          enableForWorkspaceTypeScriptVersions = true,
        },
      })
    end,
  },
  {
    "leafOfTree/vim-svelte-plugin",
    event = "LazyFile",
    ft = "svelte",
  },
}
