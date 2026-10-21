# Batch06 紧凑修订：独立 QA 入口

## 结论
2026-10-20 最后紧凑修订源的静态检查通过；正式五图已完成独立视觉终验，且逐张 SHA256 与 render_manifest.json 一致。所检源 SHA256 见 `final_source.sha256`。不是 UE 导航/碰撞或战斗验收。

- 17 条现行路线，共 **7509 个横向采样点**（含重叠点），地面支撑、2.10m 高度、横向 ±0.50m 及前向多高度离散射线均零异常。覆盖外围环路、原核心前后出口、跨区连接与六条真实折线步行路线。
- 高架另按横向 ±1m 的 **2m 宽采样带 420 点**复核，零异常；两端入口及 L 形转角保留通行。不能将离散检查称为连续体积扫掠。
- 六条步行路的 **231 个约2m间隔站位**，定向水平射线均在12m内命中指定站姿实墙/屏/设备柜。排除细柱、栏杆、管道、标志和绿植。此处“附近实体”不是全方向保护，也不等于该站位已经处于掩体背后。
- 1.65m 眼高，沿实际直线分段的前向20m视线检查，最长连续开放采样区间：南入口8m、核心→办公6m、东侧10m、西侧18m、高架7m、装卸→泵站18m。统计包含末采样区间，不把多个转弯合成虚构的70m直火线。不是对任何敌方位置、子弹穿透或实战安全的保证。
- 三个人物视角实际支持面和前0.5m净空通过：入口与东街相对眼高1.655m，桥上相对眼高1.650m。鸟瞰不是人物站立视角。

`visual_final.json` 记录五图目视与哈希核对。完整围护总览、入口、泵站与桥上眼高图通过；剖切图仅供内部结构展示。材质和建筑变化仍属地图 v1 的基础精度，并非商业游戏最终美术。

## 最后仅光照修订的证据关联
- 最终亮版源：`f19f554d9f2ba93e6f3c1d31d95b0db2ed2b5bcd78a7fecc42de8cfe1267edb3`，见 `final_source.sha256`。
- 原独立几何静态基准：`0218ca7d20d61d699ddcde2c16622befb2e80087b66e65b7cd92c019ebba177b`，见 `geometry_baseline_source.sha256`；未把旧静态测试伪写成新测试。
- `../Exports/lighting_only_source_audit.json` 的网格/非灯对象世界矩阵/材质节点指纹前后相同；独立读审实际修改脚本，只调整 SUN、world、曝光及布局hash元数据。故保留原几何、路线、镜头站位静态结果，不重复几何测试。
- 亮版五图重新逐张目视，source、layout及逐图hash均与最终manifest一致；桥上和泵站暗部清晰度提升。此关联不增加UE或战斗验收范围。

## 必须保留的限制
- `inner_west`、`retained_inner`、`elevated` 是**原直中心线参照**，已被新增实屏/设备柜主动阻断；正式通行验证采用 `pedestrian_*` 的真实绕行线。不能称原8m车道直轴全部畅通，不能称高架原直轴无阻挡。
- `existing_core_ring_limitation` 是原核心窄环的大代理限制：720样本有316条命中记录（同点可能多条）。未缩放旧核心来掩盖问题。
- `core_template_capsule_static.json` 为另行采用 Epic 官方示例胶囊高1.92m、半径0.42m的旧环静态检查，720样本通过；**不是官方 Manny 网格实测，更不是在 UE 中执行胶囊扫掠**。大代理2.10m/r0.50的依据见 `scale_basis.md`。
- 固定模板分区接口，非任意边界自动布局求解器；游戏碰撞、导航、移动、攀爬、车辆与性能均未运行验收。

## 正式证据
- `clearance_report.json` — 全图净空与支撑；按上方现行/历史轴线区别解读。
- `bridge_2m_band.json` — 高架2m带补测。
- `exposure_rays.json`、`exposure_summary.json` — 24方位与前向射线、真实直段统计。
- `cover_target_report.json` — 定向到实际实体边界的近遮蔽补测，减少固定角度射线漏检。
- `camera_final.json` — 三个人物镜头支撑/眼高/前向净空。
- `final_source.sha256`、`scale_basis.md`、`reference_review.md` — 源身份、尺度来源、图纸审查与修复记录。
- 区域补测：`office_horizontal.json`（其后仅岛面板支座微调）、`maintenance_independent.json`、`loading_independent.json`、`pump_independent.json`。单区文件外边界之外缺地不当作总场景缺地；总装现行通路另已通过。

- `route_map.svg/png` — 最终配置的六条实际绕行路线示意；不是前置设计图，辅助翼及内部模块未逐一画出，不代替完整场景。

## 可复跑
在本目录父层运行：

```sh
QA_BVH=1 blender -b site_expansion.blend --python QA/check_expansion.py --python QA/check_exposure.py --python QA/check_cover_targets.py --python QA/check_bridge_wide.py --python QA/check_final_cameras.py
python QA/summarize_exposure.py
```

BVH 使用 Blender evaluated mesh/curve/font 的世界几何（约两百万三角），仅排除明确的展示代理；不替代 UE 碰撞体。默认不设 QA_BVH 时净空脚本仍可使用 scene.ray_cast，但明显较慢。检查脚本不保存或改写场景。

## 不作为终态的材料
`compact_*first*`、`compact_*se*`、`bvh_regression_old_scene.json`、`clearance_initial_independent.json`、`exposure_initial_independent.json`、`BeforeCompactRevision/` 是过程/旧版证据；累计交付宜移至 History 或不纳入，不能当最终阻断/通过结论。旧 overview 与旧镜头亦不能替换紧凑修订同源最终五图。
