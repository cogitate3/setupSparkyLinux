# Copilot Coding Agent Instructions

Purpose: Make AI agents immediately productive in this repo by explaining the architecture, workflows, conventions, and integration points that are specific to this project.

## Big Picture
- **Goal:** One‑click post‑install setup for Sparky Linux 7.5 and other Debian Bookworm-based distros via Bash scripts.
- **Primary flow:** Entry scripts orchestrate numbered task scripts to install packages, configure shells (zsh), input methods (rime), fonts, DAV/SSHFS mounts, and autostart items.
- **Scope:** Linux desktop post‑install automation; most scripts target Debian-based systems. Some Windows config assets exist but are not the main target.

## Key Entry Points
- `901afterLinuxInstall.sh`: Main post‑install driver (Chinese README points here). Runs with `sudo` and guides installation steps.
- `install_menu.sh`: Menu-based launcher for multiple setup scripts; intended for interactive selection.
- `main_setup.sh`: High-level orchestrator used by some subflows (see also `CodeForAndy/main_setup.sh`).
- `afterAIs/**`: A parallel set of scripts (numbered similarly) for automated flows; prefer root-level scripts unless specifically working on this variant.

## Directory Map & Roles
- Root numbered scripts `001–011`, `901–903`: Discrete tasks (logging, fetching asset links, font install, zsh/OMZ, davfs2, sshfs, input methods, autostart, etc.). Numbers indicate order.
- `CodeForAndy/`: Alternate/experimental helpers and installers (e.g., `setup_*` scripts, `font_installer.sh`, `log.sh`). When adding new functionality, mirror patterns here only if it’s experimental; production logic should live at the root.
- `config/`: Config artifacts (e.g., `alacrittyForWin.toml`). Not executed; copied/applied by setup scripts.
- `tests/`: Minimal Python test scaffold; not authoritative for Bash scripts.

## Conventions & Patterns
- **Numbered scripts:** Use `NNNname.sh` to convey execution order (lower numbers first; `900+` for aggregate/after-install flows).
- **Bash only:** Scripts are `bash`-compatible; avoid `zsh` features in core installers. Prefer portable POSIX where possible but Bash is acceptable.
- **Privilege model:** Many steps require `sudo`. Detect and prompt as needed; do not assume root.
- **Debian package mgmt:** Detect package manager via `004detect_install_cmd.sh`; prefer `apt` on Debian-based systems and branch gracefully for others.
- **Font install:** Centralized in `005install_fonts.sh` and `afterAIs/005install_fonts.sh` (and related `005get_fonts.sh`, `803fonts.sh`). Reuse helpers instead of inlining curl/wget logic.
- **Zsh/OMZ setup:** Implemented by `009install_zsh_omz.sh`, `801install_zsh.sh`, `802zsh.sh`. Follow their order: install zsh → oh-my-zsh → plugins/themes.
- **Mounts:** WebDAV via `007setupDavfs2.sh`; SSHFS via `008setup_sshfs.sh`. Scripts expect packages (`davfs2`, `sshfs`) and config lines in `/etc/fstab` or on-demand mounts.
- **Autostart:** `010add_autostart_app.sh` and related helpers configure desktop autostart (XFCE target common). Place `.desktop` entries under `~/.config/autostart/`.
- **Logging:** Use provided log helpers when present (`001log2File.sh`, `CodeForAndy/log.sh`). Prefer appending to a single session log.
- **Asset fetching:** `002get_assets_links.sh` and `003get_download_link.sh` encapsulate release URL discovery. Avoid scraping ad‑hoc in other scripts.

## Typical Workflows
- **One‑shot post‑install:**
  - Run `sudo bash ./901afterLinuxInstall.sh`
  - Accept prompts; script chains numbered tasks in sequence.
- **Interactive setup menu:**
  - Run `bash ./install_menu.sh`
  - Choose modules to install/configure (fonts, zsh, input method, mounts, etc.).
- **Module‑specific run:**
  - Execute a task script directly, e.g., `bash ./009install_zsh_omz.sh`.

## Coding Guidelines for New/Updated Scripts
- **Structure:**
  - Start with `#!/usr/bin/env bash` and `set -euo pipefail` for robustness (match existing style where already set).
  - Source shared helpers if needed (e.g., detection or logging scripts) rather than duplicating logic.
- **OS/PM detection:**
  - Reuse `004detect_install_cmd.sh` to select `apt` vs. other package managers; fallback with clear messaging.
- **Idempotency:**
  - Check if packages/config already exist before installing or writing files. Use `grep -q`/`test -f` guards.
- **User prompts:**
  - Keep prompts minimal and default to safe choices. Provide `--yes`/non‑interactive paths if reasonable.
- **Localization:**
  - Some docs are bilingual; scripts should keep messages concise and neutral (English OK). Avoid hardcoding locale‑specific strings unless necessary.

## Integration Points
- **Fonts:** Place downloaded fonts under standard locations (`~/.local/share/fonts` or `/usr/local/share/fonts`) and run `fc-cache -f -v`.
- **Shell:** After zsh install, set default shell using `chsh -s /usr/bin/zsh "$USER"` and ensure OMZ install path.
- **Input method (Rime):** Use `902rime_setup.sh` to install and configure; persist user config under `~/.local/share/fcitx5/rime` or equivalent.
- **Mounts:** Ensure `/etc/fstab` lines include appropriate options; offer test mount commands.

## Testing & Validation
- There is a minimal Python test scaffold (`tests/test_hello_world.py`) not tied to Bash scripts. Prefer smoke tests inside scripts: verify binaries, versions, and config file presence.
- If adding complex logic, include a dry‑run mode (`--dry-run`) and verbose flag (`-v`) for diagnostics.

## Examples
- Font install pattern: call `005get_fonts.sh` → install to `~/.local/share/fonts` → run `fc-cache`.
- Zsh setup: `bash ./801install_zsh.sh` → `bash ./009install_zsh_omz.sh` → verify `~/.zshrc` contains OMZ init.
- WebDAV: `bash ./007setupDavfs2.sh` → confirm `mount -t davfs https://example /mnt/webdav` works.

## Where to Look First
- `README.md` / `README.en.md` for intent and entry points.
- Root `901–903` scripts for the overall flow.
- `004detect_install_cmd.sh`, `010add_autostart_app.sh` for common patterns.
- `CodeForAndy/setup_*` for experimental variants and copyable snippets.

Feedback: If any section is unclear or missing concrete hooks (e.g., shared helper sourcing, exact menu flow), tell us which task you’re implementing and we’ll refine these instructions to cover it.