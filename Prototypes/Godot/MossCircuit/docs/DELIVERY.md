# v19 源码与桌面包交付

- `MossCircuit-v19-DesktopExports-2026-10-25.zip`：累计完整Godot源码/素材/预设/构建工具与证据。
- `MossCircuit-v19-Linux-x86_64-2026-10-25.zip`：Linux可运行包；原生云端Linux窗口验证的精确ELF/PCK，附许可证与校验。
- `MossCircuit-v19-Windows-ExportOnly-x86_64-2026-10-25.zip`：Windows x86-64导出包，**仅结构/资源包检查，未在Windows运行验收**；不是安装程序，也未签名。

源码基线为v18 commit `217867b88e7225ef7c7e88b455685e5661436491`。本批不改玩法、输入、场景结构、AI、经济或源素材。大平台二进制只在独立交付包，不加入源码分支；已验收的ELF/PCK不会被之后的复现构建偷偷替换。

运行时要完整解压并保持可执行文件与`MossCircuit.pck`同目录。Linux窗口证据不代表Windows或音频验收；云端缺少ALSA输出设备以及llvmpipe VSync限制已单独记录。

源码检查：`python3 tests/run_regression.py --project . --output ../moss-v19-checks`，另执行`python3 tests/test_export_tools.py`。冷构建方法和固定官方模板SHA见`V19_DESKTOP_EXPORTS.md`。完整源码由`MANIFEST.json`校验；各平台包自带逐文件校验。原始版本源码/证据均保留，后续发布状态须以真实Git提交和读回记录为准。
