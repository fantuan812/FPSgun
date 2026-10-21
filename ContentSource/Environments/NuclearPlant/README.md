# NuclearPlant — Batch01–07 完整累计工程

## 当前入口

- **最新完整地图：[`Batch07_Refinement/site_refined.blend`](Batch07_Refinement/site_refined.blend)**，Blender 4.3+ 可直接打开。
- [全部模块索引](ALL_MODULES.md)：历史55条模块/组合库记录（含2条复用），新增7个模块家族与1个独立窄柜变体，共63条；不是63个全新独立模块。
- [Batch07说明与最终限制](Batch07_Refinement/README.zh-CN.md) / [最终预览](Batch07_Refinement/index.html) / [独立QA](Batch07_Refinement/QA/Independent/FINAL_REVIEW.md)。
- Batch07包含3个精化分块、8个独立模块资产、完整新场景、建模前v1–v4正交图、配置、生成脚本与最终实渲。原Batch01–06模块、历史总场景及导出均保留。
- `Batch06_Expansion/site_expansion.blend` 是未改动的布局/光照基线，不是当前美术终态。旧GLB/FBX仍属Batch06；本轮当前全景交付为原生Blend，GLB仅覆盖8个模块资产。

## 恢复、校验与重建

```bash
python restore_assets.py
python verify_delivery.py
python rebuild_current.py
# 可选：同时渲染最终视图
python rebuild_current.py --render
# 当前8个模块GLB；不是整图GLB/FBX
python export_current.py
```

少量旧大型原生/交换文件使用独立ZIP-LZMA，Batch07大型SVG使用更通用的ZIP-DEFLATE；脚本仅用Python标准库，无下载，自动恢复原文件名并校验压缩包和解压后SHA-256。它们不是二进制分卷，也不是需要外部下载的LFS占位符。手工解压旧LZMA档请使用7-Zip等支持ZIP-LZMA的工具。

重建读取冻结v04配置与先验参考，核验Batch06基线hash。不会隐式重建旧批次；历史脚本仍可能包含旧绝对路径，未声称全部历史脚本异地可用。先在副本重建：重建会替换该副本的当前模型与构建记录，字节校验应在重建前执行。

## 证据边界

原有核心大代理窄环限制、6个约2.09m高度的屏饰条边缘触点保留；Cycles下旧共面道路伪影未修，本轮终图与同相机基线对照使用EEVEE。静态保护带/视线采样不是UE碰撞、导航、弹道、性能、联机或官方Manny网格实测。GLB不含Blender程序化材质的烘焙贴图。

`CUMULATIVE_MANIFEST.json` / `SHA256SUMS` 是当前恢复后清单；`REPOSITORY_MANIFEST.json` 是仓库物理存储清单。`python verify_delivery.py --baseline` 仅核验保留的旧交付字节（变更根文件取`RepositoryVerification/Batch01-06_RootSnapshot/`），不把历史几何验收改写为本轮新测试。旧`DeliveryVerification/`和`RepositoryVerification/summary.json`仍明确属于Batch01–06；当前增量发布验证见`RepositoryVerification/Batch07/`。

根`manifest.json`、`delivery_manifest.json`、`README_zh.md`为Batch01历史记录。最早预览页原字节保存在根快照中，不是当前场景。
