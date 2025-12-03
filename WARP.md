# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common commands and usage

### Primary entrypoint: interactive installer

This repository is a collection of Bash scripts to perform post-install setup on Sparky Linux 7.5 and other Debian Bookworm–based systems.

The canonical entrypoint is the interactive menu script:

```bash
sudo bash ./901afterLinuxInstall.sh
```

This will:
- Initialize logging under `/tmp/logs/901afterLinuxInstall.sh.log` (exact filename may vary).
- Present a categorized menu of desktop apps, CLI tools, and package managers.
- Allow installing or uninstalling each item individually or in bulk.

If root is not used, `check_root` in the script will exit; always run via `sudo` (or as root in a controlled environment).

### English/Chinese usage docs

High-level usage and the list of menu options are documented in:
- `README.en.md`
- `setup.en.md`
- `README.md`
- `setup.md`

These describe the same entrypoint (`901afterLinuxInstall.sh`) and group items into:
- Essential desktop enhancements
- Advanced desktop applications
- Command-line tools
- System tools and platforms (Snap, Flatpak, Homebrew, Docker, etc.).

### Sub-project: CodeForAndy tools

Under `CodeForAndy/`, there is a separate menu-driven manager for development-related tools (Alacritty, ChatGPT/TerminalGPT/TGPT CLIs, Rime, fonts, etc.). Its entrypoint is:

```bash
cd CodeForAndy
bash ./main.sh
```

`CodeForAndy/main.sh`:
- Must **not** be run as root (it explicitly exits if `EUID == 0`).
- Checks for required helper scripts like `setup_alacritty.sh`, `setup_chatgpt.sh`, `setup_terminalgpt.sh`, `setup_tgpt.sh`, `setup_rime.sh`, and `setup_fonts.sh`.
- Provides an interactive menu to run each helper script.

### Logs and troubleshooting

- Core logging utilities are defined in `001log2File.sh`.
- Most higher-level scripts log to files under `/tmp/logs/` via the `log` function.
- When debugging, inspect the most recent file in `/tmp/logs/` that matches the script name you ran (for example, `901afterLinuxInstall.sh` or `903new_after.sh`).

## High-level architecture

### Overall structure

Top-level Bash scripts are mostly numbered and fall into two categories:
- **Core helpers (00x–01x)**: reusable functions for logging, GitHub release discovery and downloading, font installation, keybinding tweaks, autostart configuration, etc.
- **Menu/installer scripts (9xx)**: user-facing interactive installers that compose the helpers to perform actual work.

There are also two major subdirectories:
- `CodeForAndy/`: development tooling installers with their own menu and helper scripts.
- `afterAIs/`: alternate/older versions of many of the helper and installer scripts (useful as reference, but the root-level scripts and `901afterLinuxInstall.sh` should be treated as canonical, as they are referenced from the README and manuals).

### Core helper scripts

Key helper scripts used across the installers:

- `001log2File.sh`
  - Defines `log`, `set_log_file` and color constants.
  - Provides leveled logging (DEBUG/INFO/WARN/ERROR) and maintains a global `CURRENT_LOG_FILE` pointing to the active log file.
  - Meant to be sourced by other scripts; when run directly, it demonstrates usage.

- `002get_assets_links.sh`
  - Sourced by other scripts to talk to the GitHub Releases API using `curl` and `jq`.
  - Exposes `get_assets_links`, which populates global variables:
    - `LATEST_VERSION`: latest tag (e.g., `v1.0.4`).
    - `DOWNLOAD_LINKS`: array of asset URLs for that release.

- `003get_download_link.sh`
  - Sources `001log2File.sh` and `002get_assets_links.sh`.
  - Provides two key functions:
    - `get_download_link <releases_url> [regex]`: populates `LATEST_VERSION` and/or a single `DOWNLOAD_URL` matching the asset regex.
    - `install_package <DOWNLOAD_URL>`: downloads to `/tmp/downloads`, and if the file is:
      - `.deb`: installs via `dpkg`, falling back to `apt-get install -f` on dependency issues.
      - `.tar.gz`/`.tgz`: sets `ARCHIVE_FILE` and returns a special status so the caller can handle manual installation.

- `005install_fonts.sh`
  - Provides `install_fonts` (can be run standalone or sourced).
  - Installs a curated set of fonts (JetBrains Mono, Hack, LXGW WenKai, WQY, Noto CJK, FiraCode, emoji fonts) and the `fnt` font manager.

- `006double-Esc-to-sudo.sh`
  - Defines `double_esc_to_sudo`, `install_double_esc_sudo`, and `uninstall_double_esc_sudo`.
  - When installed, double-pressing `Esc` in Bash/Zsh prepends `sudo` to the current command via a `bind -x` Readline hook.

- `010add_autostart_app.sh`
  - Provides utilities to manage `.desktop` files under `~/.config/autostart`:
    - `add_autostart_app <Name> <Exec> <yes|no> [args…]` (with optional minimize behavior depending on desktop environment).
    - `toggle_autostart_app <Name> <enable|disable>`.
    - `list_autostart_apps` to introspect current autostart entries.
  - Used by the main installer to automatically add some apps (e.g., Plank, Angrysearch) to autostart.

These helpers are designed to be shared by all higher-level installers. When adding new functionality, prefer reusing these patterns rather than inlining new logic.

### Main installer: `901afterLinuxInstall.sh`

`901afterLinuxInstall.sh` is the primary post-install automation script described in the README and manuals.

**Key responsibilities:**
- Source helper modules: `003get_download_link.sh`, `005install_fonts.sh`, `006double-Esc-to-sudo.sh`, `010add_autostart_app.sh` (and related helpers they in turn source).
- Initialize logging (`log "/tmp/logs/$(basename "$0").log" ...`).
- Provide foundational utilities:
  - `check_root`: enforces running as root.
  - `check_and_install_dependencies`: ensures required packages are installed via `apt`.
  - `check_deb_dependencies`: inspects `.deb` files with `dpkg-deb -f` and installs missing dependencies.
  - `show_package_dependencies`: prints dependency trees for repo packages via `apt-cache depends`.
  - `check_if_installed`: unified package/command presence check across `dpkg`, `snap`, `flatpak`, and `$PATH`.
  - `get_package_version`: returns either the version from `dpkg -l` or from a provided `--version` command.
  - `display_items`: prints menu entries in colored multi-column format using `paste` and `column`.

**Installation/uninstallation functions:**
- Groups of `install_<name>` / `uninstall_<name>` functions manage individual applications:
  - Desktop enhancements: Plank, Angrysearch, Pot-desktop, Geany, Stretchly, AB Download Manager, LocalSend, SpaceFM, Krusader, Konsole, fonts.
  - Desktop/CLI apps: Tabby, Warp Terminal, Telegram, Brave, VLC, Windsurf, PDF Arranger, etc.
  - Command-line helpers: Neofetch, micro, cheat.sh, eg, eggs.
  - Package managers and platforms: Snap, Flatpak, Homebrew, Docker & Docker Compose.
- Many installers use `get_download_link` + `install_package` to fetch the latest GitHub release and then post-process archives (e.g., Angrysearch, micro).
- Some installers add desktop autostart entries via `add_autostart_app`.

**Menu system:**
- `show_menu` defines arrays for each category:
  - `desktop_enhance`, `command_enhance`, `cli_enhance`, `software_library`.
  - Renders them grouped with explanatory headings and notes on the “install all / uninstall all” numeric shortcuts (e.g., `19` / `119`).
- `handle_menu` reads a numeric choice and dispatches to:
  - Individual installers/uninstallers (e.g., `01` → `install_plank`, `101` → `uninstall_plank`).
  - Bulk operations (e.g., `19` installs all items in the desktop enhancements group, `119` uninstalls them, etc.).

When extending the menu:
- Add new entries to the appropriate category array in `show_menu`.
- Add matching `case` arms in `handle_menu` for both install and uninstall codes.
- Implement the corresponding `install_…` / `uninstall_…` functions, using `check_if_installed`, `check_and_install_dependencies`, and `get_download_link` as needed.

### Alternate installer variant: `903new_after.sh`

`903new_after.sh` is a newer variant of the main installer that:
- Sources a slightly different set of helpers (including `005get_fonts.sh`).
- Reimplements the same core patterns (`check_root`, `check_and_install_dependencies`, `check_deb_dependencies`, `show_package_dependencies`, `check_if_installed`, `get_package_version`, `display_items`).
- Defines its own set of `install_*` functions and menu.

Both `901afterLinuxInstall.sh` and `903new_after.sh` share architecture; `901afterLinuxInstall.sh` is the one linked from README and `setup*.md`, so treat it as the primary supported entrypoint unless the repository documentation is updated.

### CodeForAndy subproject

Inside `CodeForAndy/`:

- `main.sh` implements a **non-root** menu for installing/configuring:
  - Alacritty terminal
  - ChatGPT/TerminalGPT/TGPT terminal tools
  - Rime input method
  - Fonts
- It follows a slightly different architecture:
  - Enables `set -euo pipefail` and sets traps for error handling and cleanup.
  - Uses its own logging helpers (`log_error`, `log_info`, `log_success`, `log_warning`).
  - Checks for the presence of companion `setup_*.sh` scripts and system dependencies (`curl`, `wget`, `git`).
  - Provides helpers like `backup_config` to snapshot existing user configs before running installers.

Individual `setup_*.sh` scripts handle the heavy lifting (for example, `setup_alacritty.sh` implements a multi-step install with dependency checks and rollbacks, as described in `CodeForAndy/README_alacritty.md`).

When modifying or extending this area:
- Keep `CodeForAndy/main.sh` focused on menu orchestration and cross-cutting concerns (validation, backups, error handling).
- Put tool-specific logic into new or existing `setup_*.sh` scripts and document non-obvious behavior in a colocated `README_*.md`.

## Notes for Warp agents

- Many scripts make system-wide changes via `apt`, `snap`, `flatpak`, `pipx`, Docker, and Homebrew. Prefer to **ask for explicit confirmation** before running installer functions on a user’s machine, especially bulk operations.
- When editing or generating code for this repo, respect the existing modular structure:
  - Reuse core helpers instead of duplicating download/install logic.
  - Keep menu numbering, arrays, and `case` branches in sync.
  - Ensure any new installer/uninstaller uses `log` for consistent logging and supports idempotent re-runs wherever practical.
