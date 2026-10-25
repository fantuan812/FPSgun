# v17 完整工程交付

完整源码单ZIP：`MossCircuit-v17-FlowSummon-2026-10-25.zip`。解压后在Godot4.6导入`project.godot`；这是累计源码/素材完整包，不是补丁或Windows安装程序。

基线是已发布v16 commit `453960ffd8f3354cee0d0ca8b0abc762ad8b91a0`，v16完整包SHA256 `3442df072a52d9e1903fc027b9495aaf837be5a9e0ae11d6766a4ecb812e0773`。旧v16工程及Library身份保持不可变；v17另存新完整包。后续发布仍须以真实commit、远端ref和逐文件读回为准，本说明不是上传证明。

- 保留全部v16路径；本批只处理清场经验升级顺序、商店首屏可操作性及Core独立summon表现，另明确纠正旧文档世界像素换算估计。
- `MANIFEST.json`是除自身之外所有交付文件SHA256清单。源包排除`.godot`缓存、引擎及临时HOME。
- QA夹具/截图/日志放在带`.gdignore`的文档证据目录，不进入生产导入/导出；复现受控夹具要复制到独立工程。
- 作者/独立冷导入与真实窗口证据按版本留存，旧版PASS不替代本版验收。
- Windows、真人平衡与完整地牢等未完成项见 `V17_FLOW_AND_SUMMON.md`。

回归：`python3 tests/run_regression.py --project . --output /tmp/moss-v17-checks`。输出必须在工程外；新解压目录用于真正cold import。
