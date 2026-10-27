# Historical equipment-atlas v2 checkpoint

The original document below is retained verbatim as a historical description of the earlier generated 1254-pixel equipment atlas. Its statements about the old atlas being in current use or a final asset describe that past checkpoint, not the v39-equipment16 runtime. The old PNG and its import descriptor are removed from the current source tree, while historical Git commits and this record remain available.

The current replacement is a semantic editable SVG atlas with a derived 256x256 PNG and sixteen 64x64 cells. See [v39-equipment16 scope and verification](../V39_EQUIPMENT16.md). This migration changes one inventory atlas only; other legacy raster assets are not claimed migrated.

---

# Moss Circuit v2 装备图标

- `assets/items/equipment_atlas_v2.png`：实际使用内置 image_gen 生成、再使用 image_gen 修正格间留白；未经代码重绘、抠图或重采样。
- `assets/items/icon_manifest.json`：16 个 catalog ID 的独立矩形，4 武器与 12 道具；顶层 `atlas` 为 Godot 路径，`icons[id].rect` 为 `[x,y,w,h]`。
- 完整初始提示词与修复意图见 `equipment_generation_prompt.txt`。PNG SHA256：`5ac0811ec65274ed650c6ed75890561ed27070f4e5f996de14c34a5fdc5fa807`。

## 导入与显示

1254×1254 原图按 4×4 行优先排列。尺寸不能整除 4，因此边界使用 `floor(i*1254/4)`，格宽为 313 或 314；不可硬编码统一 314。使用 AtlasTexture 非破坏切片、Nearest 过滤、不生成 mipmap。常规正方形图标可直接读取全格；紧凑图标可选择清单中的 `visible_alpha_bbox_local`，其坐标相对于该格。

## 实际检查

人工查看了原始生成与修复结果：全部 16 项与 catalog 顺序一致，枪、散弹枪、蓝色长枪、圆锯，以及线圈、风扇、铁板、药贴、靴子、磁铁、芯片、透镜、电容、齿轮、弹丸袋、回收机均具有独立可辨识轮廓。第一版长枪靠近边界，因此通过 image_gen 整体缩小修复，采用修复版作为最终素材。

Pillow 仅用于读取尺寸、alpha 和散列，未保存或修改像素。16 格非空，RGBA SHA256 各不相同；可见 alpha > 32/255 的包围盒均严格位于格内。PNG 保留真实透明背景，但极低 alpha 噪点可能延伸到格边，未宣称所有非零 alpha 均有留白。像素风源图并不保证数学意义上的整数低分辨率网格。

Godot 4.6.3 在独立最小 QA 工程中完成实际资源导入，并对 16 个 AtlasTexture 切片检查非空、可见像素与唯一像素散列，结果见 `icon_test.log`。独立工程复制了相同 PNG 字节与 manifest，避免并发编辑主工程造成测试互相影响。首次缺失临时配置目录引发 editor settings 保存错误，创建完整 HOME/XDG 目录后重跑无 ERROR/WARNING。可在完整工程导入后复核：

```bash
godot --headless --path . --script docs/art/check_icons.gd
```

不将此资源检查称为 UI 实机或 Windows 验证；具体商店、背包尺寸与对比度仍由 UI 集成检查确认。

随后在实际 `godot-moss-circuit-v2` 工程已有导入缓存上再次执行 `docs/art/check_icons.gd`，同样通过 16 张切片检查。仍不代表最终 UI 布局或交互已验证。
