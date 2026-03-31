#!/bin/bash

set -euo pipefail

PROFILE="default"
PLATFORM="auto"
WITH_COMPONENTS=""
WITHOUT_COMPONENTS=""
DRY_RUN=false
ASSUME_YES=false

APT_UPDATED=false
BREW_UPDATED=false
PKG_UPDATED=false

ACTIVE_COMPONENTS=()

log() {
    printf "[%s] %s\n" "$1" "$2"
}

info() {
    log "INFO" "$1"
}

warn() {
    log "WARN" "$1"
}

error() {
    log "ERROR" "$1"
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        printf "+"
        for arg in "$@"; do
            printf " %q" "$arg"
        done
        printf "\n"
        return 0
    fi
    "$@"
}

run_shell() {
    local cmd="$1"
    if [[ "$DRY_RUN" == true ]]; then
        printf "+ %s\n" "$cmd"
        return 0
    fi
    bash -lc "$cmd"
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

detect_platform() {
    if [[ "$PLATFORM" != "auto" ]]; then
        return
    fi

    if [[ -n "${PREFIX:-}" && "${PREFIX}" == *"com.termux"* ]]; then
        PLATFORM="termux"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        PLATFORM="mac"
    elif [[ -f /etc/os-release ]] && grep -qi "ubuntu" /etc/os-release; then
        PLATFORM="ubuntu"
    else
        error "Unsupported platform. Use --platform mac|ubuntu|termux"
        exit 1
    fi
}

ensure_pkg_manager() {
    if [[ "$DRY_RUN" == true ]]; then
        return
    fi

    case "$PLATFORM" in
        mac)
            if ! has_cmd brew; then
                error "Homebrew not found. Install Homebrew first: https://brew.sh"
                exit 1
            fi
            ;;
        ubuntu)
            if ! has_cmd apt-get; then
                error "apt-get not found"
                exit 1
            fi
            ;;
        termux)
            if ! has_cmd pkg; then
                error "pkg not found (Termux)"
                exit 1
            fi
            ;;
    esac
}

pkg_update_once() {
    case "$PLATFORM" in
        mac)
            if [[ "$BREW_UPDATED" == false ]]; then
                run_cmd brew update
                BREW_UPDATED=true
            fi
            ;;
        ubuntu)
            if [[ "$APT_UPDATED" == false ]]; then
                run_cmd sudo apt-get update
                APT_UPDATED=true
            fi
            ;;
        termux)
            if [[ "$PKG_UPDATED" == false ]]; then
                run_cmd pkg update -y
                PKG_UPDATED=true
            fi
            ;;
    esac
}

install_pkg() {
    local pkg="$1"
    local required="${2:-false}"

    case "$PLATFORM" in
        mac)
            if ! run_cmd brew install "$pkg"; then
                if [[ "$required" == true ]]; then
                    error "Failed to install required package: $pkg"
                    exit 1
                fi
                warn "Skipping unavailable package: $pkg"
            fi
            ;;
        ubuntu)
            if ! run_cmd sudo apt-get install -y "$pkg"; then
                if [[ "$required" == true ]]; then
                    error "Failed to install required package: $pkg"
                    exit 1
                fi
                warn "Skipping unavailable package: $pkg"
            fi
            ;;
        termux)
            if ! run_cmd pkg install -y "$pkg"; then
                if [[ "$required" == true ]]; then
                    error "Failed to install required package: $pkg"
                    exit 1
                fi
                warn "Skipping unavailable package: $pkg"
            fi
            ;;
    esac
}

install_pkg_if_missing() {
    local binary="$1"
    local pkg="$2"
    local required="${3:-false}"

    if has_cmd "$binary"; then
        return
    fi
    install_pkg "$pkg" "$required"
}

contains_component() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

component_supported() {
    local component="$1"
    case "$component" in
        core|shell|tmux|nvim|stow|qol|node|python)
            return 0
            ;;
        server-defaults)
            [[ "$PLATFORM" == "ubuntu" ]]
            return
            ;;
        bun|docker|tailscale)
            [[ "$PLATFORM" == "mac" || "$PLATFORM" == "ubuntu" ]]
            return
            ;;
        *)
            return 1
            ;;
    esac
}

bootstrap_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh"
        run_shell "RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\
            \\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    fi

    local custom_plugins="$HOME/.oh-my-zsh/custom/plugins"
    if [[ ! -d "$custom_plugins/zsh-autosuggestions" ]]; then
        run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
    fi
    if [[ ! -d "$custom_plugins/zsh-syntax-highlighting" ]]; then
        run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_plugins/zsh-syntax-highlighting"
    fi
}

bootstrap_tpm() {
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        info "Installing tmux plugin manager (TPM)"
        run_cmd git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
}

bootstrap_nvm() {
    if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing nvm"
        run_shell "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
    fi

    if [[ "$ASSUME_YES" == true ]]; then
        run_shell "export NVM_DIR=\"$HOME/.nvm\" && [ -s \"$HOME/.nvm/nvm.sh\" ] && . \"$HOME/.nvm/nvm.sh\" && nvm install --lts && nvm alias default lts/*"
    else
        info "nvm installed. Install Node LTS later with: nvm install --lts"
    fi
}

bootstrap_pyenv() {
    if has_cmd pyenv; then
        return
    fi

    case "$PLATFORM" in
        mac)
            install_pkg_if_missing pyenv pyenv true
            ;;
        ubuntu)
            local deps=(
                make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
                wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
            )
            local dep
            for dep in "${deps[@]}"; do
                install_pkg "$dep" false
            done
            run_shell "curl -fsSL https://pyenv.run | bash"
            ;;
        termux)
            warn "Skipping pyenv on Termux. Installing system Python instead."
            install_pkg_if_missing python python false
            ;;
    esac
}

bootstrap_bun() {
    if has_cmd bun; then
        return
    fi
    run_shell "curl -fsSL https://bun.sh/install | bash"
}

install_nvim_tooling() {
    if ! has_cmd nvim; then
        warn "Neovim not installed, skipping Neovim tooling"
        return
    fi

    if has_cmd npm; then
        run_cmd npm install -g intelephense prettier @fsouza/prettierd
    else
        warn "npm not found, skipping npm-based Neovim tools (intelephense, prettier, prettierd)"
    fi

    info "Bootstrapping Neovim plugins and Mason tools"
    run_cmd nvim --headless "+Lazy! sync" +qa || warn "Lazy sync failed"
    run_cmd nvim --headless "+MasonToolsInstallSync" +qa || warn "Mason tool install failed"
}

apply_stow() {
    if ! has_cmd stow; then
        warn "stow not available, skipping symlink setup"
        return
    fi

    local dirs=(zsh tmux tmux-sessionizer bin git)

    if contains_component "nvim" "${ACTIVE_COMPONENTS[@]:-}"; then
        dirs+=(nvim)
    fi

    if contains_component "qol" "${ACTIVE_COMPONENTS[@]:-}" || contains_component "nvim" "${ACTIVE_COMPONENTS[@]:-}"; then
        dirs+=(yazi)
    fi

    if contains_component "node" "${ACTIVE_COMPONENTS[@]:-}" || contains_component "nvim" "${ACTIVE_COMPONENTS[@]:-}"; then
        dirs+=(opencode claude)
    fi

    if [[ "$PLATFORM" == "mac" ]]; then
        dirs+=(ghostty kitty karabiner aerospace)
    fi

    local d
    for d in "${dirs[@]}"; do
        if [[ -d "$d" ]]; then
            run_cmd stow -R "$d"
        fi
    done
}

install_component_core() {
    info "Installing core packages"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            local pkgs=(git curl jq ripgrep fzf fd bat tree unzip stow gh git-delta)
            ;;
        ubuntu)
            local pkgs=(git curl jq ripgrep fzf fd-find bat tree unzip stow gh git-delta)
            ;;
        termux)
            local pkgs=(git curl jq ripgrep fzf fd bat tree unzip stow gh openssh)
            ;;
    esac

    local p
    for p in "${pkgs[@]}"; do
        install_pkg "$p" false
    done
}

install_component_shell() {
    info "Installing shell packages"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            install_pkg_if_missing zsh zsh true
            install_pkg_if_missing zoxide zoxide false
            install_pkg_if_missing eza eza false
            ;;
        ubuntu)
            install_pkg_if_missing zsh zsh true
            install_pkg_if_missing zoxide zoxide false
            install_pkg_if_missing eza eza false
            ;;
        termux)
            install_pkg_if_missing zsh zsh true
            install_pkg_if_missing zoxide zoxide false
            ;;
    esac

    bootstrap_oh_my_zsh

    if [[ "$PLATFORM" != "termux" ]] && has_cmd zsh; then
        if [[ "${SHELL##*/}" != "zsh" ]]; then
            run_cmd chsh -s "$(command -v zsh)" "$USER" || warn "Failed to change default shell to zsh"
        fi
    fi
}

install_component_tmux() {
    info "Installing tmux"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            install_pkg_if_missing tmux tmux true
            ;;
        ubuntu)
            install_pkg_if_missing tmux tmux true
            ;;
        termux)
            install_pkg_if_missing tmux tmux true
            ;;
    esac

    bootstrap_tpm
}

install_component_nvim() {
    info "Installing Neovim and prerequisites"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            install_pkg_if_missing nvim neovim true
            install_pkg_if_missing make make true
            ;;
        ubuntu)
            install_pkg_if_missing nvim neovim true
            install_pkg_if_missing make make true
            install_pkg_if_missing gcc gcc true
            install_pkg xclip false
            ;;
        termux)
            install_pkg_if_missing nvim neovim true
            install_pkg_if_missing make make true
            install_pkg_if_missing clang clang false
            ;;
    esac
}

install_component_qol() {
    info "Installing QoL tools"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            install_pkg lazygit false
            install_pkg btop false
            if ! has_cmd fastfetch; then
                install_pkg fastfetch false
            fi
            install_pkg ncdu false
            install_pkg yazi false
            ;;
        ubuntu)
            install_pkg lazygit false
            install_pkg btop false
            if ! has_cmd fastfetch; then
                install_pkg fastfetch false || true
            fi
            if ! has_cmd fastfetch; then
                install_pkg neofetch false
            fi
            install_pkg ncdu false
            install_pkg yazi false
            ;;
        termux)
            install_pkg btop false
            if ! has_cmd fastfetch; then
                install_pkg fastfetch false
            fi
            if ! has_cmd fastfetch; then
                install_pkg neofetch false
            fi
            install_pkg lazygit false
            install_pkg ncdu false
            install_pkg yazi false
            ;;
    esac
}

install_component_node() {
    info "Installing Node environment"
    bootstrap_nvm
}

install_component_python() {
    info "Installing Python environment"
    bootstrap_pyenv
}

install_component_bun() {
    info "Installing Bun"
    bootstrap_bun
}

install_component_docker() {
    info "Installing Docker"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            run_cmd brew install --cask docker || warn "Failed to install Docker Desktop"
            info "Docker Desktop installed. Launch it once to finish setup."
            ;;
        ubuntu)
            install_pkg ca-certificates false
            install_pkg curl false
            install_pkg gnupg false

            run_shell "sudo install -m 0755 -d /etc/apt/keyrings"
            run_shell "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
            run_shell "sudo chmod a+r /etc/apt/keyrings/docker.gpg"
            run_shell "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \$VERSION_CODENAME) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"

            run_cmd sudo apt-get update
            run_cmd sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
                warn "Failed to install Docker CE packages, falling back to docker.io"
                run_cmd sudo apt-get install -y docker.io docker-compose-v2 || warn "Docker install fallback also failed"
            }

            run_shell "sudo systemctl enable --now docker" || warn "Could not enable/start Docker service"
            run_shell "sudo usermod -aG docker \"$USER\"" || warn "Could not add user to docker group"
            info "You may need to log out/in (or run 'newgrp docker') to use docker without sudo."
            ;;
    esac
}

install_component_tailscale() {
    info "Installing Tailscale"
    pkg_update_once

    case "$PLATFORM" in
        mac)
            install_pkg tailscale false
            ;;
        ubuntu)
            run_shell "curl -fsSL https://tailscale.com/install.sh | sh" || warn "Failed to install Tailscale"
            ;;
    esac
}

install_component_server_defaults() {
    info "Installing Ubuntu server defaults"

    if [[ "$PLATFORM" != "ubuntu" ]]; then
        warn "server-defaults is only supported on Ubuntu"
        return
    fi

    pkg_update_once

    local pkgs=(ufw fail2ban unattended-upgrades apt-listchanges)
    local p
    for p in "${pkgs[@]}"; do
        install_pkg "$p" false
    done

    run_shell "sudo systemctl enable --now fail2ban" || warn "Could not enable/start fail2ban"
    run_shell "sudo systemctl enable --now unattended-upgrades" || warn "Could not enable/start unattended-upgrades"

    run_shell "if [ -f /etc/ssh/sshd_config ]; then \
        ports=\$(grep -E '^[[:space:]]*Port[[:space:]]+[0-9]+' /etc/ssh/sshd_config 2>/dev/null | awk '{print \$2}' | sort -u); \
        if [ -z \"\$ports\" ]; then ports=22; fi; \
        for p in \$ports; do sudo ufw allow \"\$p\"/tcp; done; \
    else \
        sudo ufw allow OpenSSH; \
    fi"

    run_shell "sudo ufw default deny incoming"
    run_shell "sudo ufw default allow outgoing"

    if [[ "$ASSUME_YES" == true ]]; then
        run_shell "sudo ufw --force enable" || warn "Failed to enable UFW"
        info "UFW enabled with SSH allowed"
    else
        warn "UFW rules are configured but firewall is not enabled automatically."
        info "Enable when ready with: sudo ufw --force enable"
    fi
}

profile_components() {
    case "$PROFILE" in
        minimal)
            echo "core shell tmux nvim stow"
            ;;
        default)
            echo "core shell tmux nvim stow qol node python server-defaults"
            ;;
        full)
            echo "core shell tmux nvim stow qol node python server-defaults bun docker tailscale"
            ;;
        ubuntu-dev)
            echo "core shell tmux nvim stow qol node python server-defaults bun docker tailscale"
            ;;
        ubuntu-prod)
            echo "core shell tmux stow server-defaults docker tailscale"
            ;;
        *)
            error "Unknown profile: $PROFILE"
            exit 1
            ;;
    esac
}

print_help() {
    cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --profile minimal|default|full|ubuntu-dev|ubuntu-prod   Install profile (default: default)
  --platform auto|mac|ubuntu|termux Override platform detection
  --with a,b,c                      Add extra components
  --without a,b,c                   Skip components
  --dry-run                         Print commands without executing
  --yes                             Non-interactive mode
  -h, --help                        Show help

Components:
  core shell tmux nvim stow qol node python server-defaults bun docker tailscale
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --with)
                WITH_COMPONENTS="$2"
                shift 2
                ;;
            --without)
                WITHOUT_COMPONENTS="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes)
                ASSUME_YES=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    detect_platform
    ensure_pkg_manager

    if [[ "$PROFILE" == ubuntu-* && "$PLATFORM" != "ubuntu" ]]; then
        error "Profile '$PROFILE' is Ubuntu-specific. Use --platform ubuntu."
        exit 1
    fi

    info "Platform: $PLATFORM"
    info "Profile: $PROFILE"

    local components
    components="$(profile_components)"

    local selected=()
    local c
    for c in $components; do
        selected+=("$c")
    done

    local add_list=()
    local remove_list=()

    if [[ -n "$WITH_COMPONENTS" ]]; then
        IFS=',' read -r -a add_list <<< "$WITH_COMPONENTS"
    fi
    if [[ -n "$WITHOUT_COMPONENTS" ]]; then
        IFS=',' read -r -a remove_list <<< "$WITHOUT_COMPONENTS"
    fi

    for c in "${add_list[@]:-}"; do
        [[ -z "$c" ]] && continue
        if ! contains_component "$c" "${selected[@]}"; then
            selected+=("$c")
        fi
    done

    local filtered=()
    for c in "${selected[@]}"; do
        if contains_component "$c" "${remove_list[@]:-}"; then
            info "Skipping disabled component: $c"
            continue
        fi
        filtered+=("$c")
    done

    local final=()
    for c in "${filtered[@]}"; do
        if component_supported "$c"; then
            final+=("$c")
        else
            warn "Component '$c' is not supported on $PLATFORM, skipping"
        fi
    done

    info "Final components: ${final[*]}"

    ACTIVE_COMPONENTS=("${final[@]}")

    for c in "${final[@]}"; do
        case "$c" in
            core) install_component_core ;;
            shell) install_component_shell ;;
            tmux) install_component_tmux ;;
            nvim) install_component_nvim ;;
            stow) apply_stow ;;
            qol) install_component_qol ;;
            node) install_component_node ;;
            python) install_component_python ;;
            server-defaults) install_component_server_defaults ;;
            bun) install_component_bun ;;
            docker) install_component_docker ;;
            tailscale) install_component_tailscale ;;
            *) warn "Unknown component '$c', skipping" ;;
        esac
    done

    if contains_component "nvim" "${final[@]:-}"; then
        install_nvim_tooling
    fi

    info "Bootstrap complete"
}

main "$@"
