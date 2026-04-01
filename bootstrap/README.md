# Bootstrap

Cross-platform bootstrap scripts for this dotfiles repo.

## Entry point

- Primary: `./bootstrap/bootstrap.sh`
- Compatibility wrapper: `./setup.sh`
- Remote server bootstrap: `./bootstrap/bootstrap-remote.sh`

## Supported platforms

- macOS (`--platform mac`)
- Ubuntu (`--platform ubuntu`)
- Termux (`--platform termux`)

`--platform auto` is the default.

## Profiles

- `minimal`: `core shell tmux nvim stow`
- `default`: `core shell tmux nvim stow qol node python server-defaults`
- `full`: `core shell tmux nvim stow qol node python server-defaults bun docker tailscale`
- `ubuntu-dev`: `core shell tmux nvim stow qol node python server-defaults bun docker tailscale`
- `ubuntu-prod`: `core shell tmux stow server-defaults docker tailscale`

`server-defaults` is Ubuntu-only and installs baseline server hardening tools (`ufw`, `fail2ban`, `unattended-upgrades`, `apt-listchanges`).

`ubuntu-prod` is intentionally slim and skips language runtimes/tooling (Node, Bun, Python, Neovim).

Claude Code and OpenCode CLIs are installed automatically as part of the `node` component on:

- macOS (all profiles that include `node`)
- Ubuntu `ubuntu-dev` profile

Installers used:

- `curl -fsSL https://claude.ai/install.sh | bash`
- `curl -fsSL https://opencode.ai/install | bash`

## Common commands

```bash
# Preview actions only
./bootstrap/bootstrap.sh --dry-run --profile default

# New Ubuntu server
./bootstrap/bootstrap.sh --platform ubuntu --profile default

# New Ubuntu server (non-interactive + enable UFW)
./bootstrap/bootstrap.sh --platform ubuntu --profile default --yes

# Mac with optional exclusions
./bootstrap/bootstrap.sh --platform mac --profile full --without docker

# Minimal setup + extra components
./bootstrap/bootstrap.sh --profile minimal --with node,qol

# Bootstrap remote Ubuntu server over SSH
./bootstrap/bootstrap-remote.sh --user ubuntu --host 10.0.0.50 --port 22 --ssh-key ~/.ssh/id_ed25519 --profile default --yes

# Slim production Ubuntu host
./bootstrap/bootstrap.sh --platform ubuntu --profile ubuntu-prod --yes

# Development Ubuntu host
./bootstrap/bootstrap.sh --platform ubuntu --profile ubuntu-dev --yes
```

## Remote bootstrap

`bootstrap-remote.sh` will:

1. SSH into the target using your SSH key auth.
2. Ensure `git` exists on the remote host.
3. Clone (or update) this dotfiles repository.
4. Run `./bootstrap/bootstrap.sh --platform ubuntu ...` remotely.

Useful remote options:

- `--user`, `--host`, `--port`
- `--ssh-key`
- `--repo` (override local origin URL)
- `--dest` (remote clone path, default `~/dotfiles`)
- `--branch`

## Improvements backlog

- See `bootstrap/IMPROVEMENTS.md` for planned hardening and reliability enhancements.

## Options

- `--profile minimal|default|full|ubuntu-dev|ubuntu-prod`
- `--platform auto|mac|ubuntu|termux`
- `--with a,b,c`
- `--without a,b,c`
- `--dry-run`
- `--yes`
- `-h`, `--help`
