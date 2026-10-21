# 核心区通用模型导出

- `NuclearPlant_Core.glb`：嵌入式 glTF binary，无纹理或模型外部依赖。
- `NuclearPlant_Core.fbx`：FBX 7.4，源米制，导出轴变换 -Z forward / Y up；导入器应正常应用单位和轴变换。
- 包含完整屋顶、真实实例化后的控制台/柜组/立罐、字体/曲线转换几何，以及 3 个 1.8 m 比例参考人形。
- 不包含任何相机或灯光对象。几何灯具保留作为场景装饰。
- 材质保留 Principled 基础参数，但程序化噪声、凹凸与复杂节点没有烘焙到纹理；通用查看器/UE 的外观不等同 Blender 原场景渲染。完整 Blender 源场景是材质参考。
- 未做 UE 碰撞、导航、LOD、关卡导入或玩家运行验收；这不是已配置完毕的 UE 工程。

`export_core.py`（上级目录）非破坏性打开源文件，在独立临时场景中提取 evaluated geometry，真实展开 collection instances、应用网格修改器、转换曲线和字体。不会保存或覆盖源 `.blend`。可从构建管线单独启动 Blender 调用此脚本。

`validate_exports.py -- glb/fbx` 分别在新 Blender 进程中回读，记录对象数、三角形数、边界、材质数、设备存在、外部依赖。最终结果见 `export_validation.json`。

一次导出验证发现 glTF 默认跨场景导出了源场景内 2 个选中对象（多出 24 三角面），已修正：导出前在内存中移除源场景，仅保留完全实例化的导出场景；磁盘源不变。修正后重新导出与回读，不把初次导出误计为通过。

## 最终相机版本审计
最终 Blender 源另调整了 3 个人眼相机站位，文件哈希因此变化。导出时几何基准哈希仍如 `export_source_manifest.json` 原样保留，没有虚改导出记录。`camera_only_source_audit.json` 对真正的导出基准副本与最后源进行了 Blender evaluated geometry 比对：坐标/拓扑/UV、实例世界矩阵、材质节点及灯光均相同；仅单独记录相机变化。`export_validation.json` 通过该审计确认模型导出继续适用当前源，而不是声称源文件从未改变。
