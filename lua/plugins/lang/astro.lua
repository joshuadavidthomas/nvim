-- copied from `LazyVim/LazyVim`, license included in the `.licenses` directory at the root of the repo

return {
  -- depends on the typescript
  -- just including this to make sure it's noted
  { import = "plugins.lang.typescript" },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
        {
          name = "@astrojs/ts-plugin",
          location = LazyVim.get_pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin"),
          enableForWorkspaceTypeScriptVersions = true,
        },
      })
    end,
  },
}
