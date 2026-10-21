# NPP / Sector K-17：第三批 04_PUMP 区域

## 这次交付了什么

原始总图中 04_PUMP 泵房/水处理区已用真实模块组合替换，保持原坐标 X=-8..24、Y=-28..-4、地上高度不超过 8 m。功能区占地 32×24 m；另用三块 4×4 m 楼板组成向南延伸 12 m 的接路平台，连到灰盒既有 Y=-44 m 道路。

区域包括三组泵、吸入与回流主管、阀门、管架、两层维护附房、Z=4 m 连廊与外楼梯。既有总图的其他 7 区继续保留灰盒；不是整张地图或最终 AAA 美术成品。

先打开：
- `Region/pump_zone.blend`：可独立打开的泵区及接路平台
- `Region/site_with_pump_zone.blend`：在原总图中替换泵区后的完整上下文副本
- `Previews/pump_zone_beauty.png`：实际区域渲染
- `Previews/pump_train_detail.png`：泵组及管件近景
- `Previews/pump_zone_top.png`：区域实际俯视图
- `Previews/site_with_pump_zone.png`：全站上下文
- `index.html`：离线预览与各模块文件入口

## 有限新增资产

只有 5 类新导出模块：4 m 直管、半径 1 m 的 90° 弯头、2 m 三通、1 m 阀门段、4×2×2 m 泵组。每件都有独立 spec.json、先行外观参考及提示词、可编辑 .blend、FBX、GLB、真实 Front/Right/Top、beauty、三视图拼图和验证报告。

前两批资产按原样复用，包括墙体、门洞、窗、楼板、顶板、柱顶承托、直线连廊、转角连廊、楼梯、支柱和成对管架。准确实例与来源见 `Region/placements.json`，它记录米制世界变换矩阵，不是假定 UE 已完成导入的工程文件。

三座混凝土泵台、中间楼梯基础、四个主管盲板、接路小坡面、地面标识为本区域辅助几何，未冒充另外完成的独立模块产品。

## 尺度与动线

- 模块主网格 4 m，放置和连接以 0.25 m 为基础；细部制造尺寸、埋深及屋面避共面座接允许小于网格
- 地面东侧保留 3.75 m 宽服务通道，南侧保留 2.5 m 宽横向通道连接附房入口、泵区和外楼梯；向南 4 m 宽接路平台延伸至原道路，末端小坡连接道路 0.07 m 高差
- 外楼梯两段各升高 2 m，到达 Z=4 m；再沿东侧和北侧连廊进入上层门洞。名义宽 2 m，首批连廊保守净宽 1.75 m
- 上层通道尚未连接全站更远处的高架路线，本批通过外楼梯回到地面
- 主管轴线 Z=2 m；泵组置于高 1 m 的混凝土泵台，局部端口高 1 m，因此与主管一致
- 管道外半径 0.265 m、内半径 0.21 m；法兰外半径 0.375 m、厚 0.12 m。外径与首批管架内鞍座匹配，四处实际网格射线检查支承接触
- 主管为可扩展的检修状态组合，四端设盲板；不进行流量、压力、设备控制或真实核电系统仿真
- 屋顶相对名义座面下沉 5 mm，避免与墙顶面共面闪烁，墙顶仍为 Z=8 m。建筑内部目前是疏布置的维护空间，没有控制台等后续道具

## 真正执行的验证

`Validation/final_summary.json` 是最后摘要；每个资产目录还有 geometry/export/interface/image 四类报告。

- Blender 4.3.2 实际执行建模、渲染、导出和重新导入
- 15 张模块正交源图均为 1024×1024、ORTHO、ortho_scale=6.4 m，即 160 px/m；Front=-Y，Right=+X，Top=+Z。beauty 自适应取景不用于量尺
- 尺寸包围盒、非流形边、退化面、精确重复面、闭合组件体积方向、UV 有效性，以及 FBX/GLB 复导入尺寸/轴向均有检查
- 三通使用真实空心布尔交汇；泵具有可视连通管口。每个端口抽检孔道通透和法兰接合平面，直管/三通/阀门/泵还检查中心通路，弯头检查曲线孔壁半径
- 法兰为真实钻孔几何，螺栓头缩在接合平面以内；圆管采用平滑曲面法线和锐边分离，避免首轮粗糙的分面观感
- 区域检查楼梯到建筑的连续连接、各泵与主管的接口、真实管道和复用鞍座的座接、功能区包络及东侧通道占用
- 两个 .blend 均检查没有外部 Blend 库或图片依赖，旧 04_PUMP 占位块已移除；总图副本的地面在新楼板下开了浅槽，避免 Z=0 共面闪烁；全站副本仍保留其他 7 个区域的灰盒对象
- 前两批原始交付 ZIP 内所有文件逐一校验 SHA-256，包括其清单文件；冻结结果见 `prior_batches_freeze_after.json`

## 验证和美术边界

本批采用基础 PBR 常量材质和真实几何，尚未完成最终磨损、污渍、贴花、Trim Sheet、LOD、静态灯光 UV 重打包和运行性能预算。可见少量 Cycles 采样噪点，当前 Blender 构建不支持 OpenImageDenoise，因此关闭了降噪。

碰撞代理为简化的闭合凸体。可视管道内部有孔，不代表碰撞也允许玩家钻进管内。未进行任意三角形自交的穷举认证，焊缝接合、法兰座接、底座与支脚等有明确的设计接触。通道包围盒/接口检查不替代 UE 中实际玩家胶囊体、车辆和导航测试。

没有运行 Unreal Editor 实际导入，也没有结构、建筑规范或设备工程认证。当前是原创工业场景资产，不能用来操作或建设真实核电设施。

## AI 参考

五张参考先于建模生成；可用工具没有可核实的“Image 2.5”版本标识。弯头和三通的图像视向错误，泵图把 +Y 排出口画成了 +Z，阀门孔径文字也有歧义，已在 `References/reference_review.md` 逐件说明。参考只用于外观，严格尺寸采用规格和真实 Blender 模型。

## Unreal Engine 使用

逐件导入新模块的 export.fbx，核对单位换算后直管长 400 cm；保留匹配命名的 UCX 与 SOCKET。不要自动用凸包封住建筑门洞；管道的游戏碰撞本来就是保守代理。检查材质槽、法线与 UV，FBX 材质需要在 UE 中核对重建。

本批导出包提供新模块和区域放置表；完整区域会复用前两批已交付的模型。GLB 是可视模型替代入口，不含 UE 专用 UCX。Blender FBX 7400 与 Epic 描述的 FBX 2020.2 管线仍需目标 UE 版本兼容性实测。

官方参考：https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-static-mesh-pipeline-in-unreal-engine

## 解压与复现

全部小包解压到同一父目录，保持 `NuclearPlant/Batch03/` 结构。它们是互补的普通 ZIP，每包小于 8 MB。单独打开本批模块与两个区域 .blend 不需要前两批文件；从脚本重建区域需要相邻的 Batch01 和 Batch02 原目录。

从 Batch03 目录运行：

```sh
blender -b -t 4 -P Scripts/build_process_assets.py
blender -b -t 4 -P Scripts/verify_exports.py
blender -b -t 4 -P Scripts/verify_interfaces.py
python Scripts/verify_images.py
blender -b -t 6 -P Scripts/build_pump_zone.py
blender -b -t 4 -P Scripts/verify_scenes.py
python Scripts/package_report.py
```

最后的报告脚本还会读取相邻原始 Batch01/Batch02 交付 ZIP 以检查冻结哈希；没有这些 ZIP 时可以先运行建模和场景检查。Pillow 用于拼版及图像验证。

单件重建可追加 `-- --asset Valve`；跳过渲染可追加 `-- --no-render`。脚本只写 Batch03，同名文件会被覆盖，请先另存手工编辑版本。参数的制造规则在脚本中，不能只改 spec 外层尺寸就假定所有细节自动适配。
