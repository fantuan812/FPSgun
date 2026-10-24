# v15 反应层收口完整工程

完整单ZIP：`MossCircuit-v15-CoreReactions-2026-10-24.zip`。解压后在Godot 4.6导入`project.godot`；这是累计源码/素材完整包，不是补丁或Windows安装程序。没有分包，分包union不适用。

主要交付为FPSgun仓库 `Prototypes/Godot/MossCircuit`；发布成功以真实commit/远端读回收据为准，本文不是已上传证明。Library持久保留完整包作为备份。

- 已发布v14基线：`51a6f3ce4ae91e08212c7675df9a9f21620fee9f`，1001文件逐SHA核对后在新目录延续，v14冻结工程不动。
- v15只新增Core hurt9/death16与必要metadata、测试、说明；本轮五普通敌人+两Boss受击/死亡覆盖收口，不增加技能或玩法机制。
- 保留原1001路径。历史报告只属于原版本；本次证据在`docs/validation/v15-core/`与`independent-v15-core/`。
- `MANIFEST.json`列出除自身外全部交付文件SHA-256。独立验包核CRC、清单、基线路径与解压后的冷启动测试。
- 不带`.godot`缓存或引擎二进制，首次导入生成缓存。命令行验收需可写HOME/XDG，交付runner自动设置。

GUI/真人手感、平衡、Windows导出及其他未完成项见`docs/REACTION_COVERAGE.md`；不能将headless通过等同这些验收。
