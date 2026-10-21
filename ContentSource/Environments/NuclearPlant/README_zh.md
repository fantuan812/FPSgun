# NPP / Sector K-17

## 交付范围

原创近未来核电站场景的总图灰盒，以及首批 8 件工业连廊模块。不是现有游戏地图的复刻。当前不是整张地图的最终美术成品。

先打开：
- `ModularKit/assembly_demo.blend`：已拼接的连廊与楼梯示范场景
- `Blockout/site_graybox.blend`：224 × 192 m 总图灰盒，8 个功能分区
- `Previews/kit_gallery.png`：全部首批模块真实 Blender 渲染
- `Previews/assembly_beauty.png`：真实组合场景渲染
- `index.html`：离线预览目录

## 每个模块包含

`spec.json`、`reference_sheet.png`、`reference_prompt.txt`、`model.blend`、`export.fbx`、`export.glb`、`front.png`、`right.png`、`top.png`、`orthographic_sheet.png`、`beauty.png`，以及几何、导出、接口、图像验证 JSON。

## 模块清单

| 资产 | 尺寸 X × Y × Z (m) | 三角形 | UCX | 结果 |
| --- | --- | ---: | ---: | --- |
| SM_NPP_Catwalk_Straight_4m_A | 4 × 2 × 1.3 | 17,676 | 3 | PASS |
| SM_NPP_Catwalk_Corner90_A | 4 × 4 × 1.3 | 31,232 | 6 | PASS |
| SM_NPP_Catwalk_TJunction_A | 4 × 4 × 1.3 | 31,556 | 7 | PASS |
| SM_NPP_Stair_4x2_Rise2_A | 4 × 2 × 3.3 | 24,864 | 3 | PASS |
| SM_NPP_Railing_Open_4m_A | 4 × 0.125 × 1.1 | 3,812 | 1 | PASS |
| SM_NPP_Railing_Infill_2m_B | 2 × 0.125 × 1.1 | 4,560 | 1 | PASS |
| SM_NPP_Column_4m_A | 0.5 × 0.5 × 4 | 2,068 | 1 | PASS |
| SM_NPP_PipeSupport_2m_A | 2 × 0.5 × 2 | 3,852 | 5 | PASS |

## 验证边界

- 所有模块均由 Blender 实际执行参数化建模、渲染和导出，不是仅提供脚本
- 0.25 m 对齐网格、4 m 主模数；规范记录原点、连接点与朝向。细部制造尺寸、0.20 m 踏步以及基础埋深允许小于网格
- 连廊标称宽 2 m，栏杆内保守净宽 1.75 m。平台厚 0.20 m、栏杆高 1.10 m；楼梯 10 级、每级 0.40 × 0.20 m，总升高 2 m
- Front 从 -Y，Right 从 +X，Top 从 +Z；全部真实 ORTHO。源图均 1024 × 1024、160 px/m。预览拼图统一缩放，未单独放大薄侧面
- 包围盒、闭合网格、退化面、精确重复面、各闭合组件体积方向、UV 有效性、真实碰撞代理和接口表面均有数值检查
- 两种导出格式均在新 Blender 场景中重新导入，检查尺寸与轴向。FBX 内含单件可视网格、匹配命名的 UCX 碰撞与 SOCKET 空对象；GLB 为可视网格与接口元数据，不含 UE 专用 UCX
- 组合示范检验 8 组连接，包含 90 度转向和 2 m 高差。声明接口与真实碰撞平台边缘均有检查
- 金属框架焊接、格栅交叉、螺栓接合有刻意接触或穿插；没有宣称进行任意三角形自相交的穷举认证
- UV0 为米制平铺 UV，UV1 是有效且分岛的初版灯光 UV。正式烘焙应重新打包并按目标分辨率检查
- 只采用基础 PBR 材质，尚未制作最终磨损贴图、Trim Sheet、Decal、LOD 和正式性能预算
- 已执行 Blender 检查；没有执行 Unreal Editor 内导入、材质重建、碰撞显示与玩家行走测试，也没有安全/建筑规范认证

## 图像参考说明

8 张 AI 参考先于模块建模生成，但工具未提供可核实的“Image 2.5”版本选择。参考图存在透视、视向标错、比例失真等问题，均逐件记录在 `StyleGuide/reference_review.md`。尺寸和接口冲突时使用 spec.json 与真实 Blender 网格。不要用 AI 参考证明工程精度。

## Unreal Engine 导入建议

1. 逐件导入各目录的 export.fbx；保持 Import Uniform Scale = 1，启用场景单位换算。Blender 源单位为米，目标尺寸例如直线段为 400 × 200 cm
2. 不自动生成替代碰撞，检查导入到 Static Mesh 的 UCX。每个 FBX 只含一个可视资产及其碰撞/接口
3. 检查材质槽、法线、UV 通道；FBX 材质不保证自动保留所有 PBR 参数。GLB 可作为可视模型的替代入口
4. 用 25 cm 网格试拼；确认平台高差、楼梯斜面碰撞、边缘阻挡、胶囊体净空与朝向，再扩展场景
5. Blender FBX 导出为 7400 格式。Epic 文档描述的 FBX 管线版本为 2020.2，因此仍须在你的目标 UE 版本做实际兼容性检查

参考：Epic 官方 [FBX Static Mesh Pipeline](https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine)

## 重建

已安装 Blender 4.3.2 的环境中，从解压目录运行：

```sh
blender -b -t 6 -P Scripts/build_kit.py
blender -b -t 4 -P Scripts/verify_exports.py
blender -b -t 4 -P Scripts/verify_interfaces.py
python Scripts/verify_images.py
blender -b -t 6 -P Scripts/render_gallery.py
blender -b -t 6 -P Scripts/build_assembly.py
python Scripts/package_report.py
```

单件重建示例：`blender -b -P Scripts/build_kit.py -- --asset Straight`。
`verify_images.py` 和 `package_report.py` 使用 Pillow。几何参数来自各模块 spec.json，制造细节规则位于 build_kit.py；更改接口或尺寸后需同步检查建模规则，不可只改外层尺寸后假定适配。

灰盒重建脚本为 `Scripts/build_blockout.py`。同名输出会被重建脚本覆盖，正式编辑前请另存版本。历史调试日志保留在工作目录，压缩交付仅包含最终报告和必要脚本。
