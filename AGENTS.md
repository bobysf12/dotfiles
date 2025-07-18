# AGENTS.md - Dotfiles Repository Guide

## Repository Overview
This is a personal dotfiles repository using GNU Stow for configuration management. Contains configs for Neovim, Tmux, Zsh, Ghostty, Yazi, and other CLI tools.

## Setup Commands
- **Install all dotfiles**: `./setup.sh`
- **Stow specific configs**: `stow nvim tmux zsh ghostty yazi tmux-sessionizer bin`
- **No build/test commands** - this is a configuration repository

## Code Style Guidelines
- **Lua (Neovim)**: 4 spaces, no trailing whitespace, snake_case for variables
- **Shell scripts**: Use `#!/bin/bash`, quote variables, use `set -e` for error handling
- **Configuration files**: Follow each tool's native format (TOML, conf, etc.)

## File Structure
- Each tool has its own directory with `.config/` subdirectory structure
- Use Stow-compatible layout: `tool/.config/tool/config-files`
- Keep tool-specific configurations isolated

## Neovim Configuration
- Based on Kickstart.nvim with custom plugins in `lua/custom/plugins/`
- LSP servers: TypeScript, PHP (Intelephense), Lua
- Formatters: Stylua (Lua), Prettier (JS/TS)
- Plugin manager: Lazy.nvim

## Dependencies
- **Required**: stow, zsh, neovim, tmux, git, fzf, ripgrep
- **Optional**: eza, duf, fastfetch, lazygit, watson, thefuck, zoxide, slides