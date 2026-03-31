#!/bin/bash

set -euo pipefail

SSH_USER=""
SSH_HOST=""
SSH_PORT="22"
SSH_KEY=""

REPO_URL=""
DEST_DIR="~/dotfiles"
BRANCH=""

PROFILE="default"
WITH_COMPONENTS=""
WITHOUT_COMPONENTS=""
ASSUME_YES=false
DRY_RUN=false

log() {
    printf "[%s] %s\n" "$1" "$2"
}

info() {
    log "INFO" "$1"
}

error() {
    log "ERROR" "$1"
}

print_help() {
    cat <<'EOF'
Usage: ./bootstrap/bootstrap-remote.sh --user USER --host IP_OR_HOST [options]

Required:
  --user USER                 SSH username
  --host HOST                 SSH host or IP

Optional:
  --port PORT                 SSH port (default: 22)
  --ssh-key PATH              SSH private key path
  --repo URL                  Git repo URL (default: local origin remote URL)
  --dest DIR                  Remote clone directory (default: ~/dotfiles)
  --branch NAME               Branch to checkout before bootstrap
  --profile minimal|default|full|ubuntu-dev|ubuntu-prod
  --with a,b,c                Extra bootstrap components
  --without a,b,c             Skip bootstrap components
  --yes                       Pass --yes to remote bootstrap
  --dry-run                   Print actions without executing
  -h, --help                  Show help

Example:
  ./bootstrap/bootstrap-remote.sh \
    --user ubuntu --host 10.0.0.50 --port 22 \
    --ssh-key ~/.ssh/id_ed25519 \
    --profile default --yes
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                SSH_USER="$2"
                shift 2
                ;;
            --host)
                SSH_HOST="$2"
                shift 2
                ;;
            --port)
                SSH_PORT="$2"
                shift 2
                ;;
            --ssh-key)
                SSH_KEY="$2"
                shift 2
                ;;
            --repo)
                REPO_URL="$2"
                shift 2
                ;;
            --dest)
                DEST_DIR="$2"
                shift 2
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --profile)
                PROFILE="$2"
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
            --yes)
                ASSUME_YES=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
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

    if [[ -z "$SSH_USER" || -z "$SSH_HOST" ]]; then
        error "--user and --host are required"
        print_help
        exit 1
    fi

    if [[ -n "$SSH_KEY" && ! -f "$SSH_KEY" ]]; then
        error "SSH key not found: $SSH_KEY"
        exit 1
    fi
}

detect_repo_url() {
    if [[ -n "$REPO_URL" ]]; then
        return
    fi

    if command -v git >/dev/null 2>&1; then
        REPO_URL="$(git config --get remote.origin.url || true)"
    fi

    if [[ -z "$REPO_URL" ]]; then
        error "Could not determine repo URL. Pass --repo explicitly."
        exit 1
    fi
}

main() {
    parse_args "$@"
    detect_repo_url

    local ssh_opts=("-p" "$SSH_PORT" "-o" "BatchMode=yes" "-o" "StrictHostKeyChecking=accept-new")
    if [[ -n "$SSH_KEY" ]]; then
        ssh_opts+=("-i" "$SSH_KEY")
    fi

    local target="$SSH_USER@$SSH_HOST"
    info "Target: $target:$SSH_PORT"
    info "Repo: $REPO_URL"
    info "Profile: $PROFILE"

    if [[ "$DRY_RUN" == true ]]; then
        info "Dry run enabled. SSH command preview:"
        printf "ssh"
        for arg in "${ssh_opts[@]}"; do
            printf " %q" "$arg"
        done
        printf " %q REPO_URL=%q DEST_DIR=%q PROFILE=%q WITH_COMPONENTS=%q WITHOUT_COMPONENTS=%q BRANCH=%q ASSUME_YES=%q bash -s <REMOTE_SCRIPT\n" \
            "$target" "$REPO_URL" "$DEST_DIR" "$PROFILE" "$WITH_COMPONENTS" "$WITHOUT_COMPONENTS" "$BRANCH" "$ASSUME_YES"
        exit 0
    fi

    ssh "${ssh_opts[@]}" \
        "$target" \
        "REPO_URL=$(printf %q "$REPO_URL") DEST_DIR=$(printf %q "$DEST_DIR") PROFILE=$(printf %q "$PROFILE") WITH_COMPONENTS=$(printf %q "$WITH_COMPONENTS") WITHOUT_COMPONENTS=$(printf %q "$WITHOUT_COMPONENTS") BRANCH=$(printf %q "$BRANCH") ASSUME_YES=$(printf %q "$ASSUME_YES") bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y git
fi

if [ -d "$DEST_DIR/.git" ]; then
  git -C "$DEST_DIR" fetch --all --prune
  if [ -n "$BRANCH" ]; then
    git -C "$DEST_DIR" checkout "$BRANCH"
  fi
  git -C "$DEST_DIR" pull --ff-only || true
else
  git clone "$REPO_URL" "$DEST_DIR"
  if [ -n "$BRANCH" ]; then
    git -C "$DEST_DIR" checkout "$BRANCH"
  fi
fi

cd "$DEST_DIR"
chmod +x bootstrap/bootstrap.sh setup.sh || true

BOOTSTRAP_CMD=(./bootstrap/bootstrap.sh --platform ubuntu --profile "$PROFILE")
if [ -n "$WITH_COMPONENTS" ]; then
  BOOTSTRAP_CMD+=(--with "$WITH_COMPONENTS")
fi
if [ -n "$WITHOUT_COMPONENTS" ]; then
  BOOTSTRAP_CMD+=(--without "$WITHOUT_COMPONENTS")
fi
if [ "$ASSUME_YES" = "true" ]; then
  BOOTSTRAP_CMD+=(--yes)
fi

"${BOOTSTRAP_CMD[@]}"
REMOTE_SCRIPT

    info "Remote bootstrap complete"
}

main "$@"
