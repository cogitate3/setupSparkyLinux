# Modular Main Program for setupSparkyLinux

- 新增分支：在 `modules/` 新建 `*.mod.sh`，填 `MOD_*` 元数据 + 实现 `mod_install` 等生命周期 + 末尾 `register_module`。
- 删除分支：删文件或在 `conf/modules.yaml` 标记禁用（主程序后续可扩展读取）。
- 批量执行：
  - `./setup.sh --run fonts,zsh --action install`
  - `./setup.sh --tags desktop --action uninstall`
  - `./setup.sh --group "Storage & Mount"`
- 演练：`DRY_RUN=1 ./setup.sh --menu`

打包时间：2025-12-01T18:13:53
