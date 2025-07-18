#!/bin/bash

# Define packages
apt_packages="stow zsh neovim tmux git fzf ripgrep"
non_apt_packages="eza duf fastfetch lazygit watson thefuck zoxide slides"
stow_folders="zsh nvim tmux ghostty yazi tmux-sessionizer bin"

# Install dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS
    brew update
    brew install $apt_packages $non_apt_packages
else
    # Linux
    sudo apt update
    sudo apt install -y $apt_packages

    # Install non-apt packages
    # eza
    if ! command -v eza &> /dev/null; then
        curl -fsSL https://github.com/ogham/exa/releases/latest/download/eza-linux-x86_64.zip -o eza.zip
        unzip eza.zip -d eza_tmp
        sudo mv eza_tmp/eza /usr/local/bin/
        rm -rf eza.zip eza_tmp
    fi

    # duf
    if ! command -v duf &> /dev/null; then
        curl -fsSL https://github.com/muesli/duf/releases/latest/download/duf_0.8.1_linux_amd64.deb -o duf.deb
        sudo dpkg -i duf.deb
        rm duf.deb
    fi

    # fastfetch
    if ! command -v fastfetch &> /dev/null; then
        curl -fsSL https://github.com/LinusDierheimer/fastfetch/releases/latest/download/fastfetch-linux-x86_64 -o fastfetch
        sudo install fastfetch /usr/local/bin/
        rm fastfetch
    fi

    # lazygit
    if ! command -v lazygit &> /dev/null; then
        curl -fsSL https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_amd64.deb -o lazygit.deb
        sudo dpkg -i lazygit.deb
        rm lazygit.deb
    fi

    # watson
    if ! command -v watson &> /dev/null; then
        pip3 install --user td-watson
    fi

    # thefuck
    if ! command -v thefuck &> /dev/null; then
        sudo apt install -y python3-pip
        pip3 install --user thefuck
    fi

    # zoxide
    if ! command -v zoxide &> /dev/null; then
        curl -fsSL https://github.com/ajeetdsouza/zoxide/releases/latest/download/zoxide-x86_64-linux.tar.gz | tar -xzf - -C /tmp
        sudo install /tmp/zoxide /usr/local/bin/
    fi

    # slides
    if ! command -v slides &> /dev/null; then
        curl -fsSL https://github.com/maaslalani/slides/releases/latest/download/slides-linux-amd64 -o slides
        sudo install slides /usr/local/bin/
        rm slides
    fi
fi

# Stow configurations
stow $stow_folders

# Set Zsh as default shell
chsh -s $(which zsh)

echo "Dotfiles setup complete!"

