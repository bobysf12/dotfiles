# Bootstrap Improvements

This file tracks next improvements for the Ubuntu server bootstrap flow.

## Production hardening

- Add SSH hardening component:
  - disable password auth
  - disable root login
  - keep public key auth enabled
- Add stricter Fail2ban defaults for `sshd`:
  - lower retry count
  - longer ban duration
  - persistent ban database
- Add explicit UFW app/port policies for common containerized services:
  - default deny inbound
  - allow SSH only
  - opt-in component flags for app ports

## Ops reliability

- Add `needrestart` support and reboot-required notice handling.
- Add post-bootstrap verification checks:
  - `ufw status`
  - `fail2ban-client status`
  - `docker info`
  - `tailscale status`
- Add a minimal backup helper for production hosts:
  - copy/backup compose files
  - backup `.env` templates
  - capture named volume metadata

## DX improvements

- Add `--ssh-port` override for firewall configuration (for non-22 SSH hosts).
- Add `--setup-only` mode in `bootstrap-remote.sh` (skip clone/update, run bootstrap only).
- Add optional JSON/text install report output for CI or server provisioning logs.
