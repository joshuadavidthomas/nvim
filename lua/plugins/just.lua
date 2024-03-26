return {
  -- Vim syntax for Justfiles
  {
    "NoahTheDuke/vim-just",
    event = "LazyFile",
    ft = { "\\cjustfile", "*.just", ".justfile" },
  },
  {
    "IndianBoy42/tree-sitter-just",
    event = "LazyFile",
    ft = { "\\cjustfile", "*.just", ".justfile" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
  },
}
