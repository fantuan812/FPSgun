# 原创核心区设备模块

Blender 4.3.2，米制。`core_props.py` 的 `build_props()` 返回集合字典；无需运行 `__main__`。或从 `props.blend` append 对应 collection，使用 Collection Instance，不要把所有模板叠在一处当场景。

核心区建议使用：
- `CP_ReactorConsole`：2.500 × 1.242 × 1.257 m，操作者朝向为 -Y 面；斜顶封闭柜体、键区、显示屏、急停按钮。
- `CP_ElectricalCabinetBank`：3.150 × 0.915 × 2.420 m，面板朝 -Y。
- `CP_VerticalServiceTank`：2.225 × 2.418 × 5.028 m，含底座、接管法兰、阀门、检修梯。
- `CP_RedGuardPanel`：上栏杆长度 2 m；底脚总包围宽度 2.12 m，高 1.245 m。模块排布按 2 m 轴距或按实际连接调整，不应误把脚外廓当净通道宽度。

其它四件是方向调整之前制作的候选附属资产，非核心区必选：压力容器撬装、双变压器、道路隔离墩、工具托盘。全部原创程序几何，无第三方素材或纹理。

## 验证
`inventory.json` 是保存前对源几何的包围盒统计；修改器只在原有外轮廓内倒角。`orthographic/camera_manifest.json` 记录 24 个正交相机视图；每件各 front (-Y)、side (+X)、top (+Z)，相机 `ORTHO`，不存在透视。`*_sheet.png` 是三视图排版。

实际完成：Blender 生成和保存，24 张正交渲染，修正控制台未封闭斜顶及按钮高度。未做 UE 导入/碰撞/LOD 验收。源资产集合无相机、灯光、世界设置。验证渲染脚本另外建立灯光，不修改源 blend。

再生成：`blender -b --python core_props.py`。正交渲染：`blender -b --python render_verify.py`；拼图：`python make_sheets.py`（Pillow）。
