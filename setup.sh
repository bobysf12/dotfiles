#!/bin/bash

# Define packages
packages="stow zsh neovim tmux git fzf eza duf fastfetch lazygit watson thefuck zoxide"
stow_folders="zsh nvim tmux ghostty"

# Install dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS
    brew update
    brew install $packages
else
    # Linux
    sudo apt update
    sudo apt install -y $packages
fi

# Stow configurations
stow $stow_folders

# Set Zsh as default shell
chsh -s $(which zsh)

echo "Dotfiles setup complete!"

