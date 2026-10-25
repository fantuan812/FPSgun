# v16 完整工程交付

完整源码单ZIP：`MossCircuit-v16-PlayabilityCharge-2026-10-25.zip`。解压后在Godot4.6导入`project.godot`；这是累计源码/素材完整包，不是补丁或Windows安装程序。

主要交付路径仍是FPSgun仓库 `Prototypes/Godot/MossCircuit`。发布成功须以真实commit及远端读回收据为准，本文不是已上传证明。v15旧Library包保持独立历史身份；v16另存新完整包，不覆盖v15。

- v15基线：`14ebe583f911b66f36200d05e886fe6e0176c456`。原ZIP SHA256为 `be77a6280235247b1c02ff8f75b1124fba54b126c079c512a74ac68e91610cdc`，恢复1140文件，1139项清单SHA256全匹配。
- v16保留全部v15路径，仅改输入/界面生命周期、HUD布局及Warden charge表现选择；详情见 `V16_PLAYABILITY.md`。
- 历史报告仅属于原版本；本次作者证据在 `docs/validation/v16-runtime/`，独立证据另有报告。
- `MANIFEST.json`列出除自身之外全部交付文件SHA256。打包校验CRC、清单、基线路径；源包不带`.godot`缓存、引擎或临时GUI驱动。
- 真正冷导入请使用新解压目录。测试入口：`python3 tests/run_regression.py --output /tmp/moss-checks`，结果必须在工程外；runner自动使用可写HOME/XDG。

v16已取得真实Linux窗口的部分流程证据，不能扩展为Windows、真人平衡或所有动作整合都已验收。精确范围见本次报告。
