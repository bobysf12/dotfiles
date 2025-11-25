#!/bin/bash

# Define packages
packages="stow zsh neovim tmux git fzf eza duf fastfetch lazygit watson thefuck zoxide ripgrep slides bat fd-find htop tree curl jq gh delta glow micro ncdu ranger"
termux_packages="zsh neovim tmux git fzf zoxide ripgrep bat fd htop tree curl jq gh micro ncdu ranger openssh"
stow_folders="zsh nvim tmux ghostty yazi tmux-sessionizer bin opencode"

# Install dependencies
if [[ -n "$PREFIX" ]] && [[ "$PREFIX" == *"com.termux"* ]]; then
    # Termux
    echo "Detected Termux environment"
    pkg update
    pkg install -y $termux_packages
    echo "Note: Some packages (stow, eza, duf, fastfetch, lazygit, watson, thefuck, slides) are not available in Termux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
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

# Stow configurations (skip on Termux if stow not available)
if [[ -n "$PREFIX" ]] && [[ "$PREFIX" == *"com.termux"* ]]; then
    echo "Skipping stow on Termux - you'll need to manually symlink configs"
    echo "Consider copying configs directly to their destinations"
else
    stow $stow_folders
fi

# Install Node.js via nvm
echo "Installing nvm (Node Version Manager)..."
if [[ -n "$PREFIX" ]] && [[ "$PREFIX" == *"com.termux"* ]]; then
    # Termux: Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
else
    # Linux/macOS: Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi

# Install Python via pyenv
echo "Installing pyenv (Python Version Manager)..."
if [[ -n "$PREFIX" ]] && [[ "$PREFIX" == *"com.termux"* ]]; then
    # Termux: Install pyenv dependencies and pyenv
    pkg install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
    curl https://pyenv.run | bash
else
    # Linux/macOS: Install pyenv
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: pyenv available via brew
        if ! command -v pyenv &> /dev/null; then
            brew install pyenv
        fi
    else
        # Linux: Install pyenv dependencies and pyenv
        sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git
        curl https://pyenv.run | bash
    fi
fi

# Set Zsh as default shell (skip on Termux)
if [[ -n "$PREFIX" ]] && [[ "$PREFIX" == *"com.termux"* ]]; then
    echo "On Termux, zsh is available but shell changing works differently"
    echo "You can run 'zsh' to start zsh or set it up in your terminal app"
else
    chsh -s $(which zsh)
fi

echo ""
echo "=== Post-installation steps ==="
echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "2. Install Node.js: nvm install --lts && nvm use --lts"
echo "3. Install Python: pyenv install 3.11.0 && pyenv global 3.11.0"
echo "4. Add to your shell config (~/.zshrc):"
echo '   export NVM_DIR="$HOME/.nvm"'
echo '   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
echo '   export PATH="$HOME/.pyenv/bin:$PATH"'
echo '   eval "$(pyenv init -)"'

echo "Dotfiles setup complete!"

