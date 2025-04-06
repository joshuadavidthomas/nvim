set dotenv-load := false
set export := true

[private]
default:
    @just --list

[private]
fmt:
    @just --fmt

# NVIM_APPNAME="nvim.new" nvim $argv
bootstrap CONFIG_DIR="nvim.new":
    NVIM_APPNAME="{{ CONFIG_DIR }}" nvim --headless -c "Lazy! sync" +qa
    # NVIM_APPNAME="{{ CONFIG_DIR }}" nvim --headless -c ":lua require('snacks.lazygit').open()" +qa
    NVIM_APPNAME="{{ CONFIG_DIR }}" nvim --headless -c "UpdateRemotePlugins" +qa
