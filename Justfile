set dotenv-load := false
set export := true

nvim_config := justfile_directory() + "/init.lua"
export nvim := "nvim --headless -u " + nvim_config

[private]
default:
    @just --list

[private]
fmt:
    @just --fmt

# NVIM_APPNAME="nvim.new" nvim $argv
bootstrap CONFIG_DIR="nvim.new":
    $nvim -c "Lazy! sync" +qa
    $nvim -c "UpdateRemotePlugins" +qa
    # NVIM_APPNAME="{{ CONFIG_DIR }}" nvim --headless -c ":lua require('snacks.lazygit').open()" +qa

update:
    $nvim -c "Lazy! update" +qa
    $nvim -c "lua require('mason.api.command').MasonUpdate()" +qa
    $nvim -c "UpdateRemotePlugins" +qa
