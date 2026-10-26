# v20 战斗HUD可读性交付

- `MossCircuit-v20-HudReadability-2026-10-25.zip`：累计完整Godot源码、素材、导出预设、构建工具与分层证据。
- `MossCircuit-v20-Linux-x86_64-2026-10-25.zip`：完整Linux包，用于新安装/恢复；精确PCK已做有限原生窗口流程和实际Warden下沿验证。
- `MossCircuit-v20-Windows-ExportOnly-x86_64-2026-10-25.zip`：完整Windows导出包，**未在Windows执行验收**，未签名、不是安装程序。
- `MossCircuit-v19-to-v20-Update-2026-10-25.zip`：已有原始v19用户的手动PCK更新。聊天大小限制下使用两个20 MB以内分卷与中文说明；先合并校验，解压到独立目录，核对原v19程序/PCK，备份旧PCK，再手动替换。任何原始哈希不符时不要套用增量更新；完整包可用于恢复。

源码基线为v19 commit `3c323eb4de102efa02e99c17619ec917bc0c1a78`。只有 `ui/moss_ui.gd` 的生产代码改变；碰撞、伤害、AI、技能几何/时间、RNG、经济、场景和素材不变。v19原始Library包/证据保持历史身份，不被更新包覆盖。更新不会自动操作用户电脑。

精确包和分卷SHA256见 `BINARY_DELIVERIES.json`，包内各自附校验。Linux/Windows程序与v19相同，新PCK是完整资源包，不是二进制差分。只使用已验收精确构建，没有在GUI之后偷偷重建。冷构建工作流可复现，但不承诺引擎生成的PCK字节完全复现。

验证：作者/独立冷导入+60个脚本入口、3项Python负测、761项PCK检查、1600步/构建权威轨迹一致。独立原生控制矩阵24例/版本；精确Linux导出只验有限流程、首个Warden边缘和Rooms启动/战斗，不声称完整v20通关、死亡重试、Windows、音频或真人平衡验收。视口外裁切未改变；原生日志保留ALSA失败后dummy回退和llvmpipe VSync警告。

源码运行：`python3 tests/run_regression.py --project . --output ../moss-v20-checks`，再执行 `python3 tests/test_export_tools.py`。详细边界见 `V20_HUD_READABILITY.md` 和 `validation/independent-v20/QA_REPORT.md`。GitHub分支状态以实际提交/引用读回为准。
