# PR: Add modules for 001–004 / 010 / 011

## What changed
- Add modules:
  - logging (001)
  - gh-assets (002)
  - gh-download (003)
  - detect-installer (004)
  - cmd-manager (011)
- Enhance module:
  - autostart (010) now supports check/status and custom APP_EXEC.

## Examples
```bash
LOG_FILE=/tmp/setup.log ./setup.sh --run logging --action install
OWNER_REPO="sharkdp/fd" ./setup.sh --run gh-assets
OWNER_REPO="sharkdp/fd" ./setup.sh --run gh-download
./setup.sh --run detect-installer --action status
CMDS="git curl jq" ./setup.sh --run cmd-manager --action install
APP_NAME=plank ./setup.sh --run autostart --action install
```
