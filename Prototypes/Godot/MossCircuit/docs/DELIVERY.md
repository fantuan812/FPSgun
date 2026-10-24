# v13 恢复重建完整工程

本次交付 `MossCircuit-v13-Rebuild-2026-10-24.zip`，标准单 ZIP，解压得到同名工程目录，直接在 Godot 4.6 中导入其中 `project.godot`。本包是完整源码与累计资源，不是仅含四张新图的补丁，也不是 Windows 安装程序。

若从 FPSgun 仓库取得完整 `Prototypes/Godot/MossCircuit` 目录，无需下载历史v12分包，直接导入该目录。远端是否已发布以实际 commit 为准，本文不是上传成功证明。

- 基线：v12 commit `6d393134da0a29a7c62a821abf50440e6d304f25`，699个文件逐 Git blob SHA验证。
- 新增：crawler/flanker受击9帧、死亡16帧及本次重建的metadata、测试、文档。
- 保留v12全部累计文件；历史验证报告仍标注各自版本。没有恢复/复用遗失旧v13的验收结论，也不宣称与旧841文件原包相同。
- `MANIFEST.json` 列出除其自己外全部交付文件 SHA-256；ZIP逐项验证解包字节与清单一致。
- 不含 `.godot` 缓存或 Godot 引擎二进制。首次导入由本机生成缓存。

Linux云环境运行测试时，HOME和XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME均需指向可写目录；仅设HOME不足以覆盖继承的XDG设置。headless测试不等于真人实玩或Windows导出验收。
