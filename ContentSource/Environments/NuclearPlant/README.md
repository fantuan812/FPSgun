# NuclearPlant — Batch01–08 完整累计工程

## 当前入口

- **最新完整地图：[`Batch08_Refinement/site_refined.blend`](Batch08_Refinement/site_refined.blend)**，Blender 4.3+ 可直接打开。
- [全部模块索引](ALL_MODULES.md)：67 条模块/组合记录，含历史复用与派生变体，不代表 67 个全新家族。本批新增 3 个家族 + 1 个独立低台阶盖板变体，共 4 个模块资产。
- [Batch08 说明与限制](Batch08_Refinement/README.zh-CN.md) / [最终预览](Batch08_Refinement/index.html) / [独立 QA](Batch08_Refinement/QA/Independent/FINAL_REVIEW.md)。
- 本批保持既有场地范围，59 个新增精化实例、2 个带旧场景上下文的独立分块、4 个模块 Blend/GLB、完整新场景、建模前 v01–v04 正交参考、配置、脚本、同机位前后图和终图。
- 所有 Batch01–07 资产及历史整体场景保留。`Batch07_Refinement/site_refined.blend` 是本轮未改动的输入基线。旧 Batch06 整图 GLB/FBX、Batch07 模块 GLB 都不是当前 Batch08 交换导出；当前整图交付为原生 Blend，当前 GLB 覆盖 4 个模块。

## 恢复、校验与重建

```bash
python restore_assets.py
python verify_delivery.py
python rebuild_current.py
# 可选：同一命令串行重建并渲染当前全部视图
python rebuild_current.py --render
# 当前 4 个模块 GLB，不是整图 GLB/FBX
python export_current.py
```

大型历史原生/交换文件使用独立 ZIP-LZMA；Batch07/08 大型 SVG 优先使用普通 ZIP-DEFLATE；少量超限源图使用 ZIP-LZMA。恢复脚本仅用 Python 标准库，无下载，恢复原路径并校验压缩前后 SHA-256。不是二进制分卷、空 LFS 指针或私有链接依赖。手工解压 ZIP-LZMA 请使用 7-Zip 等兼容工具；所有当前模块及整体 Blend 均直接可开。

重建读取本批冻结 v04 配置与前置参考，检查 Batch07 基线 hash，不隐式重建旧批次。历史脚本可能含旧绝对路径，未声称全历史脚本异地重建通过。请在副本重建，先验字节校验会因合法重建输出而变化。不要同时开多个 Blender 大场景进程。

## 证据与限制

这是 Blender 静态建模、回读与重建验证，不是 UE 碰撞/导航/弹道/性能/联机验收，也不是官方 Manny 骨架/网格实测。原核心大代理窄环限制与既有路线边缘触点保留，未声称本批修复；旧道路共面问题仍在，EEVEE 同机位对照不等于修复几何。GLB 只含几何与基础 PBR，程序化织物/噪声材质未烘焙；未完成游戏 LOD、碰撞和纹理烘焙或最终 AAA 美术验收。

`CUMULATIVE_MANIFEST.json` / `SHA256SUMS` 是当前恢复后清单；`REPOSITORY_MANIFEST.json` 是仓库物理清单。当前发布验证见 [`RepositoryVerification/Batch08/`](RepositoryVerification/Batch08/README.md)。`python verify_delivery.py --baseline` 仅核验 Batch01–06 旧交付字节（变更根文件使用已有历史快照），不重新宣称历史几何测试通过。Batch07 发布证据仍保留原日期/范围；本轮不新增重复根快照，前一版本根文件由 Git 提交 `df37461c5b71415431f3131ac1157982a4cfd2c5` 保留。

根 `manifest.json`、`delivery_manifest.json`、`README_zh.md`、早期 `DeliveryVerification/` 是历史记录，不是当前入口。
