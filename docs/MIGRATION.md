# MIGRATION.md — 从 901/903 主脚本迁移到 setup.sh

## 目标
- 新增或删除功能 = 只操作 `modules/*.mod.sh`，主程序 `setup.sh` **无需改动**。
- 日志与错误处理、依赖安装、GitHub 下载等全部由 `lib/` 统一提供。

## 迁移步骤
1. 将旧脚本中的具体安装逻辑搬到对应模块的 `mod_install` / `mod_uninstall`。
2. 把零散的 `command -v` / `apt install` 改为 `ensure_cmd/ensure_pkg`。
3. 下载类统一使用 `gh_latest_asset_url/gh_pick_asset` + `log_cmd`。

## 兼容入口（可选）
为了平滑迁移，保留旧入口：
- `901afterLinuxInstall.sh` / `903new_after.sh` 内只保留一行跳转：
  ```bash
  exec "$(dirname "$0")/setup.sh" --menu
  ```

## 常见问题
- **权限**：需要 `sudo` 的步骤，都由 `log_cmd "描述" sudo ...` 调用。
- **演练**：设置 `DRY_RUN=1` 确认流程与依赖是否正确。
- **定制**：可在模块内读取自定义变量（如 `APP_NAME` / `OWNER_REPO`），由调用者注入。
