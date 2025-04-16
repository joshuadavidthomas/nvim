local p = require("utils.path")

-- language setup
vim.g.node_host_prog = p.platformdirs("mise").user_data_dir .. "/installs/npm-neovim/latest/bin/neovim-node-host"
vim.g.python3_host_prog = vim.fn.stdpath("config") .. "/.venv/bin/python"
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
