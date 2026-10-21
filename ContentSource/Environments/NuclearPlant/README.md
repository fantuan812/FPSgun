# NuclearPlant — Batch01–06 完整累计交付

## 从这里开始

- **当前完整场景地图：`Batch06_Expansion/site_expansion.blend`**。直接用 Blender 4.3+ 打开。
- **全部模块索引：`ALL_MODULES.md` / `ALL_MODULES.json`**，包含各批全部原生模块、共享库 collection、参考/正交图、当前和历史场景入口。
- `Batch01` 保持原顶层布局（`ModularKit/`、`Blockout/` 等）；`Batch02/`–`Batch05_Core/` 均为 legacy 历史档案。`Batch06_Expansion/` 是 current 当前地图，不要将早期灰盒当成新版。
- 包内包含所有历史批次，不依赖另下载旧包；保留全部历史原生总场景、模块库、导出、参考/正交图、脚本、配置与验证证据。

## 一键重建当前地图

在此目录运行 `python rebuild_current.py`，需要 Blender 4.3+ 在 PATH。加 `--render` 可重建并渲染。它调用 `Batch06_Expansion/rebuild.py`，从包内核心源与区域复用源重建四个扩建区域、连接模块库、完整地图，不修改历史批次。

重新生成当前总场景 GLB/FBX：`python export_current.py`。程序材质未烘焙，交换格式不保证与 Blender 外观一致。

**历史脚本按原交付保留，部分含原工作机绝对路径；本次没有声称 Batch01–05 所有旧脚本均能异地一键全量重建。** 历史原生模型/场景与库的异地重开结果见 `DeliveryVerification/blender_open_check.json`。当前地图异地重建结果见同目录说明与报告。

## 独立小 ZIP 备份

完整 ZIP 是全部交付。另有每包小于7.9 MB的独立 ZIP 备份，解压到**同一个目录**即可合并出 `NuclearPlant/`；它们不是二进制分卷，不需要拼接字节或 `.z01`。以包外 `small_zips_manifest.json` 为精确包含清单。

如果巨型交换格式使用 ZIP-LZMA 方法14，会在小包清单注明：请使用7-Zip等支持ZIP-LZMA的解压器（Python zipfile也支持），不要依赖不支持该方法的系统内置解压器。若最终交换格式仍超过单包限制，则小包仅不含清单明确列出的交换格式，全部原生源与可重建导出脚本仍保留；不能称其包含全部交换格式。

## 证据与限制

- Batch06 各新增模块、分区和整体地图保留建模前技术正交图、造型参考及时间/审查记录。严谨二维技术图是工程投影权威；AI概念图不冒充严格尺寸图。历史参考与建模后正交图分别标识，不逆向伪造历史顺序。
- 扩建通道采用2.10 m高、半径0.50 m的保守静态检查代理，不是官方Manny网格实测。原核心大代理窄环限制保留；1.92 m/r0.42 m的官方示例胶囊尺寸静态测试不等于真实Manny或UE运行验收。
- 这是五区连通地图与模块工程，不是UE已验收成品。碰撞、导航、跳跃、攀爬、多玩家交火、性能和最终材质烘焙尚需目标引擎验收。
- 净空/掩体/视角最终结论以 `Batch06_Expansion/QA/` 的当前报告和 `DeliveryVerification/` 为准，不沿用被退回的旧稀疏场地报告。
- 累计封包排除Scratch、History/PreCompact、缓存、`.blend1`、临时日志；不附第三方官方原图。原交付模块与当前必需依赖没有因去重而丢失。

## 校验

`CUMULATIVE_MANIFEST.json` 和 `SHA256SUMS` 记录包内文件SHA-256。`python verify_delivery.py` 检查全部清单文件；`DeliveryVerification/` 记录实际异地重开与当前重建范围。根目录旧 `manifest.json` / `delivery_manifest.json` 属于Batch01历史档案，新累计索引请使用大写命名文件。
