# v21 冷凝与碎霜构筑交付

- `MossCircuit-v21-ColdSnap-2026-10-25.zip`：累计完整 Godot 源码、素材、导出预设、构建工具与分层验证证据。
- `MossCircuit-v21-Linux-x86_64-2026-10-25.zip`：完整 Linux 包，供首次安装/恢复；精确 PCK 已通过有限原生窗口获取与使用新组合的流程。
- `MossCircuit-v21-Windows-ExportOnly-x86_64-2026-10-25.zip`：Windows x86-64 导出，**未在 Windows 执行验收**，未签名、不是安装程序。
- `MossCircuit-v20-to-v21-Update-2026-10-25.zip`：只适用于包内所列原始 v20 程序/PCK 哈希的手动更新，不是独立游戏。聊天交付使用两个不超过 20 MB 的原始分卷和中文说明。先合并校验并独立解压，关闭游戏、核验原文件、另存旧 PCK 备份后才手动替换。首次安装或任何基线哈希不符时用完整 v21 包。

精确包、分卷、说明 SHA256 见 `BINARY_DELIVERIES.json`，包内另附逐文件索引。程序 ELF/EXE 与 v20 不变，新 PCK 是完整资源包而非二进制差分。更新不自动操作用户电脑；旧 v20 文件和 Library 身份保留为历史。完整源包和平台包单独保存供恢复。只交付已验收精确构建，没有在 GUI 验收之后重建；冷构建工作流可复现，但不承诺引擎生成 PCK 的字节复现。

内容：新增 Cryo Sprayer（44 scrap）和 Fracture Coil（28 scrap），当前 7 武器/27 模块。另一种武器类型的主命中才可消耗冷凝标记，另一把 Cryo 不行；消耗同时移除其减速。旧 6 武器/26 模块定义和旧素材不变，无新模式/音频/存档/联网。扩展商品池有意改变同 seed 商店结果；只保证同内容版本、相同操作序列的确定性。

验证：作者/独立冷导入 + 63 脚本、233 输入不变、Python 3、美术 33、精确 PCK 790 项。独立控制夹具验证双模式/两方向、交易与素材；精确 Linux 普通操作 seed 433 从 122 scrap 买入 Cryo 与 Coil 后剩 50，保留 Rivet，显示 ACTIVE，部署后观察锥形喷射与目标标记。这不是完整 v21 通关、原生 16 伤害逐帧测量、Windows、音频或真人平衡认证；ALSA/VSync 环境限制见原始日志。

源码回归：`python3 tests/run_regression.py --project . --output ../moss-v21-checks`；Python 安全负测：`python3 tests/test_export_tools.py`；美术资源检查：`python3 docs/art/check_cryo_resources.py . ../v20-source`（第二参数必须是已核验 v20 源码根）。详见 `V21_CRYO_BUILD.md`、`validation/independent-v21/QA_REPORT.md`。GitHub 远端状态以实际提交/引用读回为准，不由此交付文档推断。
