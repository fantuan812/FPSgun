# 累计交付验证

- `source_copy_manifest.json`：原交付/冻结树逐文件SHA256及排除清单；历史源与最终源均只读，源文件复制字节一致。
- `blender_open_check.json`：从完整ZIP异地解包后，所有原生`.blend`逐一重开。检查对象或mesh数据块、图像依赖和库依赖；数据专用Geometry库不误判为空场景。
- `rebuild_verification.json` / `rebuilt_scene_check.json`：第二个异地副本删除四个区域及总场景后，在项目外的工作目录执行根`rebuild_current.py`。新scene必须与封包原scene的对象数、实例数、顶点/面数、世界矩阵/几何指纹（1e-5精度）相符；初始解包副本和正式源不改动。
- `full_archive_verification.json`：验证流程起始完整ZIP的CRC与清单哈希。随后仅加入本验证报告与说明；实际最终完整ZIP与小ZIP的精确文件SHA、CRC/解包结果保存在包外同名transport manifest与最终verification receipt。原生模型字节不因加入报告改变。
- `verification_summary.json`：检查范围汇总。

以上是Blender原生工程/静态场景验证，不是UE碰撞、导航、Manny网格、运行性能或实战验收。Batch01–05历史脚本仅保留，部分原工作机绝对路径未迁移；未声称整个历史脚本链一键重建通过。当前地图的脚本路径由`__file__`定位，不依赖旧下载包。

原Batch06旧稀疏布局的QA/Relocation记录不用于本次结论；本目录是当前累计包重建证据入口。最终静态/视觉范围和原核心大代理窄环限制仍见`../Batch06_Expansion/QA/README_FINAL.zh-CN.md`。
