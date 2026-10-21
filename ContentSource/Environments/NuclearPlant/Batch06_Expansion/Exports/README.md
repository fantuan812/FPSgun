# Batch06 全场景通用模型导出

`NuclearPlant_FullSite.glb` 与 `NuclearPlant_FullSite.fbx` 为总场景，不是单一模块：保留 Batch05 核心区、控制办公区、维修物流区、泵区、装卸区、地面道路和高架连接。

- 真实展开集合实例，曲线/字体转换为网格并应用几何修改器；单独隔离导出场景避免跨场景重复对象。
- 保留屋顶、设备、原核心区 1.8 m 尺度人形和场地 2.10 m 方块净空代理；后者不是 Manny 模型。
- 不导出灯光或相机对象；几何灯具仍保留。
- 源单位为米。GLB 由规范进行 Y-up 转换；FBX 使用 -Z forward / Y up 的轴变换。
- 通用导出仅保留 Principled 材质参数。程序化纹理/噪声/凹凸未烘焙，查看器或 UE 外观不等于 Blender 原图。
- 未进行 UE 导入、碰撞、导航、LOD 或真实角色运行验收。

`export_site.py` 非破坏性打开 `site_expansion.blend`，不会保存源。`validate_exports.py -- glb/fbx` 在全新 Blender 进程回读，比较网格、三角形、材质数、包围盒、各区域网格数量及依赖。`finalize_exports.py` 汇总并核对哈希。以最终 `export_validation.json` 为准。

`GLB_imported_overview.png` 仅是独立重导入后的结构核验图（通用材质、独立验证灯光），不是主场景最终亮版效果；主场景五图见上级 `renders/`。最终亮版源与导出基准源的对应证明见 `lighting_only_source_audit.json`，它确认只改日光/世界/曝光，几何与材质指纹不变。
