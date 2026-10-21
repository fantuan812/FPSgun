# NPP / Sector K-17：第二批建筑模块

## 交付状态

已实际完成 7 件建筑模块、21 张同尺度正交渲染、7 张先行 AI 外观参考、FBX/GLB 导出，以及与首批资产组成的双层维护设施样段。原创布局与造型语言，不复制 AZ3 地图。本批是基础 PBR 建筑套件，不是整张核电站地图的最终写实成品。

先看：
- `Previews/architecture_beauty.png`：实际 Blender 拼装效果
- `Previews/architecture_kit_gallery.png`：7 件新模块总览
- `architecture_demo.blend`：60 个模块实例的组合场景，已内嵌所需网格
- `index.html`：离线预览、每件规格、正交图和导出链接
- `Validation/final_summary.json`：数值验收摘要
- `Validation/visual_review.md`：实际看图审查与质量边界

## 新模块

| 模块 | X × Y × Z (m) | 三角形 | UCX |
| --- | --- | ---: | ---: |
| 实墙 Wall_Solid | 4 × 0.3 × 4 | 8,228 | 1 |
| 门洞墙 Wall_Door | 4 × 0.3 × 4 | 17,552 | 6 |
| 窗墙 Wall_Window | 4 × 0.3 × 4 | 17,644 | 5 |
| 90° 墙角 Wall_Corner90 | 4 × 4 × 4 | 16,564 | 3 |
| 楼板 Floor | 4 × 4 × 0.25 | 972 | 1 |
| 顶板 Roof | 4 × 4 × 0.25 | 972 | 1 |
| 柱顶承托 ColumnHead | 0.75 × 0.75 × 0.25 | 1,304 | 1 |

合计 63,236 个三角形。每件目录位于 `Assets/`，含 spec.json、外观参考、提示词、真实 .blend、FBX、GLB、front/right/top、三视图拼图、beauty 和 4 类验证报告。

## 接口与首批复用

- 主模数 4 m，对齐网格 0.25 m。制造细节与面板厚度允许小于网格
- 墙体原点在起端地坪中心线；墙高 4 m、整体包络厚 0.30 m。门洞净宽 2 m、净高 3 m，无门槛
- 地板原点在西南角完成面，向下厚 0.25 m；顶板原点在西南角底面，向上厚 0.25 m
- 墙角两接口有 0.25 m 偏移，按 spec.json 的 socket 坐标对齐，不能直接把其包围盒角点当墙中心线
- 复用首批直线连廊、升高 2 m 楼梯、4 m 开放式栏杆与 4 m 支柱，共 4 种类型。未修改首批资产
- 两段楼梯由 Z=0 升至 Z=4，接 4 m 连廊进入上层门洞。门洞 2 m 宽，连廊保守内部净宽 1.75 m
- 建筑支柱基点 Z=-0.50，柱顶 Z=3.50；承托从 Z=3.50 到 3.75；楼板底 Z=3.75、完成面 Z=4
- 保存的示范场景共 60 个模块实例。中间楼梯基础及地台为场景辅助几何，不算新增模块资产
- 中央上层屋顶故意留空以检视内部。样段不是完整封闭建筑设计，未进行结构或建筑规范认证

## 验证结果及边界

1. 7 件模型均执行了真实 Blender 参数化建模、渲染和导出。不是仅提供未执行脚本
2. Front 从 -Y、Right 从 +X、Top 从 +Z；均为 ORTHO、1024 × 1024、ortho_scale=6.4 m，即 160 px/m。21 张轮廓像素尺寸误差均为 0 px。beauty 的取景各自适配，不作为尺寸依据
3. 包围盒、闭合网格、退化面、精确重复面、闭合组件体积方向和 UV 有效性检查通过。没有宣称穷举认证任意网格相交
4. FBX 和 GLB 均在新 Blender 场景复导入。最大包围盒误差约 0.000000477 m。FBX 的 UCX 代理检查闭合与凸性
5. 门洞碰撞与可视网格均有通透射线抽检，实测净口 2 × 3 m。楼板、屋顶及承托分别测试碰撞高度和真实可视表面高度，包括凹下的面板接缝
6. 组合场景检查 4 组通行接口及 8 组柱/承托/楼板连接。通行接口最大浮点位置误差约 0.000000954 m；承托竖向间隙为 0
7. 首批交付清单中 149 个文件前后 SHA-256 校验一致。详见 batch01_freeze_before/after.json
8. 仍未运行 Unreal Editor 实际导入、胶囊体行走、目标平台性能测试。数值 PASS 不等于完整项目最终验收

## 材质、UV 与碰撞

采用基础 PBR 常量材质和真实几何：混凝土芯体、面板、金属门窗框、玻璃、锚栓、屋面与柱顶加劲肋。尚未制作最终磨损、贴花、Trim Sheet、LOD 或场景级性能预算。

UV0 为米制平铺投射，UV1 为有效的逐面初版灯光图集；正式烘焙需要按分辨率重新打包和检查 padding。材质槽保留，但 FBX 不保证完整还原 Blender 的 PBR 参数，特别是玻璃，应在 UE 内重建。窗墙 GLB 包含 KHR_materials_transmission 和 KHR_materials_ior，目标导入器支持情况仍需确认。

FBX 每件包含一个三角化可视网格、匹配命名的 UCX 凸代理和 SOCKET 空对象；GLB 提供可视网格与接口，不含 UE 专用 UCX。门洞代理留空，窗玻璃区域阻挡，楼板/屋顶代理桥接细小面板缝，柱顶代理采用整体保守盒。皮层粘接、框架座接、玻璃入框与金属焊接有刻意接触或重叠。

## 图像参考

所有模块先生成外观参考，再建立实际模型。可用图像工具没有提供可核实的“Image 2.5”版本标识。参考存在顶视图画成剖切、透视、比例错误等问题，逐件记录在 `References/reference_review.md`；冲突时采用 spec.json 与实际 Blender 几何。AI 图不作为精度证明。

## UE 导入检查建议

逐件导入 export.fbx，Import Uniform Scale=1，并确认单位换算后墙宽为 400 cm、门洞净宽为 200 cm。检查轴向、法线、UV、材质、UCX 和 socket；不要以自动生成的凸包封住门洞。用 25 cm 网格与首批试拼，再检查碰撞可视化及玩家净空。

源文件使用 Blender 4.3.2 的 FBX 7400；Epic 的 FBX 管线文档描述 2020.2，因此目标 UE 版本的实际兼容性检查仍不可省略。官方参考：https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine

## 解压与重建

全部小包解压到同一父目录，保留 `NuclearPlant/Batch02/` 结构。它们是互补的普通 ZIP，不是 .z01 分卷。仅打开本批单件 .blend 或 architecture_demo.blend 不依赖首批外部文件；从脚本重建组合场景需要首批仍在 `NuclearPlant/ModularKit/`，并保留首批 manifest.json 与 delivery_manifest.json。

从 Batch02 目录执行：

```sh
blender -b -t 6 -P Scripts/build_architecture.py
blender -b -t 4 -P Scripts/verify_exports.py
blender -b -t 4 -P Scripts/verify_interfaces.py
python Scripts/verify_images.py
blender -b -t 6 -P Scripts/build_assembly.py
python Scripts/package_report.py
```

单件重建可追加 `-- --asset Door`；组合场景只更新保存和验证、不重渲染可追加 `-- --validate-only`。Pillow 用于图像检查和预览拼版。

各 spec.json 声明固定接口和制造要求；尺寸生成规则在 build_architecture.py 内，不能只改 spec 外层尺寸便假定所有细节自动适配。base_geometry.py 是首批通用网格库的独立副本。本批脚本只写 Batch02，重建会覆盖本批同名输出，编辑前请另存版本。
