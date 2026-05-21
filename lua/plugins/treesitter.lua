-- Nvim Treesitter configurations and abstraction layer
return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- The archived `main` branch is a separate rewrite with different setup.
    -- This config targets the legacy branch layout.
    branch = "master",
    version = false, -- last release is way too old and doesn't work on Windows
    build = ":TSUpdate",
    event = "LazyFile",
    lazy = require("utils.vim").opened_to_file, -- load treesitter early when opening a file from the cmdline
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treesitter** module to be loaded in time.
      -- Luckily, the only things that those plugins need are the custom queries, which we make available
      -- during startup.
      require("lazy.core.loader").add_to_rtp(plugin)
      local runtime_dir = plugin.dir .. "/runtime"
      if vim.uv.fs_stat(runtime_dir) then
        vim.opt.rtp:prepend(runtime_dir)
      end
      -- Register custom query predicates/directives early so injection queries work
      -- before the full treesitter config runs. The frozen `master` branch exposes
      -- a Lua module here; `main` moved this to a runtime plugin file.
      local ok = pcall(require, "nvim-treesitter.query_predicates")
      if not ok then
        local predicate_file = plugin.dir .. "/plugin/query_predicates.lua"
        if vim.uv.fs_stat(predicate_file) then
          dofile(predicate_file)
        end
      end
      require("utils.treesitter_compat").patch_nvim_treesitter_query_predicates()
    end,
    config = function(_, opts)
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if ok then
        configs.setup(opts)
      else
        require("nvim-treesitter").setup(opts)
      end

      -- Register yaml parser for yaml.tpl filetype
      vim.treesitter.language.register("yaml", "yaml.tpl")
    end,
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>", desc = "Decrement Selection", mode = "x" },
    },
    ---@type TSConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      injections = { enable = true },
      ensure_installed = {
        "astro",
        "bash",
        "c",
        "css",
        "diff",
        "dockerfile",
        "fish",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "gotmpl",
        "html",
        "htmldjango",
        "javascript",
        "jinja",
        "jinja_inline",
        "jsdoc",
        "json",
        "json5",
        "jsonc",
        "just",
        "liquid",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "ninja",
        "printf",
        "python",
        "query",
        "regex",
        "ron",
        "rst",
        "rust",
        "svelte",
        "toml",
        "tsx",
        "twig",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    opts = function()
      local tsc = require("treesitter-context")
      Snacks.toggle({
        name = "Treesitter Context",
        get = tsc.enabled,
        set = function(state)
          if state then
            tsc.enable()
          else
            tsc.disable()
          end
        end,
      }):map("<leader>ut")
      return { mode = "cursor", max_lines = 3 }
    end,
  },
}
