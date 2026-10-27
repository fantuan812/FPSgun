# v5 武器与机制扩展图标

新增 `assets/items/build_expansion_atlas_v5.png` 为内置 image_gen 实际生成图，保留原 PNG 字节。完整提示词见 `build_expansion_generation_prompt.txt`。未用 Python 或矢量图替代绘制；Pillow 仅用于读取尺寸、alpha 和散列。

SHA256：`e729eae41caa9ee73cf9382468f5efba65aa60dd125f14175ed3946241571d1a`

## 接入

第三份 `build_expansion_icon_manifest.json` 使用既有 schema：顶层 `atlas` 与 `icons[id].rect`。旧 24 图标的两个 PNG 和两份 manifest 已逐字节与 v4 比对，均未改动。UI 合并三份 lookup，不在旧图集覆写槽位。

图集实际为 1774×887、4 列×2 行，边界 `floor(i*size/cells)`，使用清单精确 rect；不硬编码单格尺寸。行优先：

1. `return_disc` 回旋飞盘：三大弯刃与青色回转轨迹，区别旧圆锯。
2. `shock_mortar` 震荡迫击炮：短粗炮筒与支架。
3. `return_spool` 回收线轴：绿色能量缆线与卷盘。
4. `blast_fuse` 余烬引信：短辫引线与橙色燃烧末端。
5. `echo_chamber` 回声腔：两个紫铜喇叭口。
6. `gravity_anchor` 重力锚：紫色中心与三爪。
7. `medic_seed` 医疗种子：红盖、绿芽与透明种子胶囊。
8. `phase_capacitor` 相位电容：横向青紫双端器件与相位电弧。

## 验证与边界

- 生成后实际查看全部八格，独立轮廓和行序正确，无可见切边；不是同一部件换色。
- 8 格非空且 RGBA hash 各不相同，alpha > 32/255 的可见包围盒严格位于各格内部。原有极淡 alpha 残留保留。
- 所有新增 ID 与 v5 catalog 匹配，旧 24 图与映射字节一致。
- Godot 4.6.3 独立最小工程实际导入后，8 张 AtlasTexture 非空、可见像素、唯一性检查通过；日志 `build_expansion_test.log`，脚本 `check_build_expansion_icons.gd`。主工程导入后可运行同脚本复核。
- 源图是高分辨率像素风生成素材，不宣称原生 64×64 逐像素网格。Nearest、无 mipmap；生成留白不完全达到提示词比例，但可见内容未越格。素材检查不等同于最终 UI 或 Windows 实机检查。

单 PNG 素材预览已 Library 保存并回读确认尺寸 1774×887、1541039 字节，无读取警告：`historical-library-reference-01`。此为素材图集，不是游戏运行截图。
