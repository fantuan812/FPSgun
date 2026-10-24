# v14 守门者反应层完整工程

本次完整单ZIP为 `MossCircuit-v14-WardenReactions-2026-10-24.zip`。解压后在Godot 4.6导入目录中的`project.godot`；这是累计源码/素材完整包，不是补丁或Windows安装程序。没有分包，分包union不适用。

主要交付仍为FPSgun仓库的 `Prototypes/Godot/MossCircuit`。发布状态以真实远端commit与读回收据为准，本文不是已上传证明。Library保留完整包作为持久备份。

- 基线：已发布v13 commit `56a6c721850fc3ef67caa0f766661a3970eb6a59`，870文件逐manifest SHA核对。
- 新增范围：现有Warden的hurt9/death16两动作与必要manifest、测试、说明；不新增玩法机制。
- v13全部路径保留，历史证据仍属原版本；最终本批报告在 `docs/validation/v14-warden/`。
- `MANIFEST.json`逐文件列出SHA-256（不含它自身）；独立验包核CRC、清单、基线路径和解压后cold测试。
- 不含`.godot`缓存或Godot引擎；首次导入生成缓存。Linux测试需为HOME及三XDG设置可写目录，可使用交付的run_regression.py自动配置。

真实GUI/真人操作、Windows导出、平衡及完整Boss招式差异化仍非本批验收范围。
