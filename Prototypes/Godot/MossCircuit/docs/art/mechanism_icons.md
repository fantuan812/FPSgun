# v4 独特机制图标

新增图集 `assets/items/mechanism_atlas_v4.png` 使用内置 image_gen 实际生成，原始 PNG 字节不变，无 Python 绘制、裁切、重采样。完整提示词见 `mechanism_generation_prompt.txt`。

SHA256：`0ca0aa10d67ce1fd7b2d6097cc75c4b653fdc6ae659a7c282f1807609f6149a6`

## 映射与兼容

旧 16 图标图集和 `icon_manifest.json` 保持不变。新 `mechanism_icon_manifest.json` 仍使用顶层 `atlas`、`icons[id].rect`，由 UI 合并两份查找表。实际大小 1774×887，4 列×2 行，边界取 `floor(i*size/cells)`，切片宽高为 443 或 444，不应硬编码尺寸。

行优先顺序：链电继电器、战利电池、冲刺树脂、镜面护壳、荆棘冠、血能阀、拾荒地雷、脉冲靴。视觉分别是双端子蓝电弧、绿电池、橙胶罐、银青镜盾、尖刺空心环、红液阀门、黄黑雷盘、推进双靴，不能用同一线圈换色替代机制区别。

## 检查与限制

- 实看所有图标，顺序一致，轮廓独立且无切边；苔绿、奶油旧钢、铜锈与青蓝发光延续旧素材风格。
- 读取 alpha 检查，8 格均非空且 RGBA SHA256 不同，alpha > 32/255 的可见内容完全在格内。生成间距并未精确达到提示词的 17%，最窄留白较小，但不跨格。
- 独立最小 Godot 4.6.3 工程实际导入并逐项构造 AtlasTexture，8 张切片可见像素、非空与唯一性检查通过，见 `mechanism_test.log`。复验脚本 `check_mechanism_icons.gd` 可在主工程导入后运行。
- 使用 Nearest、不启用 mipmap；这是像素风高分辨率生成素材，不宣称原生低分辨率逐像素绘制。保留极淡 alpha 边缘，不进行代码抠图。
- 此处资源检查不等于 UI 实机、Windows 或完整构筑玩法测试。

单独 PNG 已保存 Library 作为素材预览，而非游戏运行截图：`libfile_7f339a6b1d888191ad4bdb38642bebe0`。
