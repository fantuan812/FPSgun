# Batch07 — 有限工业美术精化

## 当前交付
- `site_refined.blend`：完整累计场景，Batch06布局、核心建筑/楼梯/门洞/桥道/已有尺度代理保留。
- `Assets/`：7种可复用模块及1个窄柜派生变体的独立Blend；`Exports/`：各模块GLB；`ALL_MODULES.json`：精确包络/面数/参考路径。
- `Regions/`：核心外立面、东泵务场、西南物流场三个改造分块。
- `References/`：建模前正交三视图、结构隐藏图与整图布置；v02保留修正后的精确尺寸，v03更新两个改造分块的4个实体柜补强，v04补充窄柜及单个泵务pad三视图/结构图/总布置。
- `Config/design_v04.json`：最终有效配置；`Scripts/`：生成、拼装、渲染、验证、导出源码。
- `renders/`：最终全图、切顶、3张眼高、模块总览及同相机前后对照。

## 美术变化
1. 核心外立面增加有真实厚度/百叶/检修叶/挂件的设备框，主滑门停靠与保守运动区避让。
2. 原12个相同大棚内部区分为泵务/电气与物流接收用途：薄板斜顶、梁柱支撑、散热鳍片与绝缘子、双管法兰/弯头/支座、托盘与布覆绑带货组。
3. 原三面实体屏墙包络保留：下2.4m混凝土、上2.1m有节点的实心石墨钢屏。开放管架不计作实体遮挡，移除旧柜造成的可避免退化通过实体检修柜补回。
4. 增加pad分缝、齐平排水格栅、少量功能标识与克制粗糙度变化；基线日光/世界光不变。

这是灰混凝土/石墨钢/克制红黄的工业题材创作，只参考AZ3一类工业氛围，不声称精确复刻。

## 先图后建模证据
- `QA/reference_freeze.json`：首轮参考、配置、生成器hash及建模前UTC。
- `QA/build_record_initial.json`：首轮模型晚于参考冻结。
- `QA/reference_freeze_v02.json` + `QA/build_record_v02.json`：独立审查后，先修正支撑、尺寸、门区/货组相交与遮挡，再重建。
- `QA/reference_freeze_v03.json` + `QA/build_record_v03_rebuild.json`：4柜局部补强，保留该版独立重建记录。
- `QA/reference_freeze_v04.json` + `QA/build_record.json`：最后1个窄柜变体填补已发现的实体遮挡缺口，先三视图/分区布置，后重建。
- `Config/render_cameras.json`独立记录终图构图相机调整，不改几何；`QA/render_provenance.json`记录每张图的实际源场景hash。
- 原始设计与各次冻结记录保留，不用模型渲染倒充先验参考。普通三视图与明确标记的“隐藏屋面/布罩结构图”分开。

## 重建
需要Blender 4.3及其Python/numpy；已有冻结图，不必重新生成参考。

```bash
blender -b -t 8 --python rebuild.py
blender -b -t 8 --python Scripts/verify_scene.py
MESA_SHADER_CACHE_DIR=/tmp/b07_mesa blender -b -t 8 --python Scripts/render_scene.py -- site_overview site_cutaway core_entry pump_eye logistics_eye module_gallery
blender -b --python Scripts/export_modules.py
```

与`../Batch06_Expansion/site_expansion.blend`相邻保存本目录。构建器会核基线和各冻结输入hash，若已变更则停止，不会静默采用其他版本。固定种子7021。

## 验证边界
- 静态射线与相交检查不是UE胶囊、导航、弹道或联机验收。
- 8条路线检查仅证明新增几何在采样的2m宽/2.10m高保护带未引入干涉；不替代原场景完整碰撞合格结论，也不消除历史核心通道限制。
- 场景内2.10m显示代理不是官方Manny网格/骨架，不声称官方骨架验收。
- 原有共面道路在Cycles会产生黑块，原始未修改Batch06亦复现；最终与对照统一使用原EEVEE引擎避免该渲染问题，未声称已重做道路拓扑。诊断见`QA/render_diagnosis.md`。
- 独立全场采样仍有6个原有上饰条边缘触点（南门路线3个、核心至控制1个、物流至泵务2个，命中高度约2.09m），前后相同，本轮未修；详见`QA/legacy_touchpoints.json`。
- GLB保留几何与基础PBR值，但Blender程序化材质噪声未烘焙为GLB贴图；完整材质以Blend为准。

## 本轮抽样结论与质量边界
- 独立既定抽样：剔除开放管架后，地面2384条、9°仰射2384条及已发现问题的3690条局部密采，均无相对于Batch06的12m近遮挡丢失。只说明该抽样集，不声称全图任意敌位均安全。
- 最终几何为7模块家族、1个X缩放0.45窄柜派生变体、154实例。各模块及变体提供独立Blend/GLB；没有把旧版整图GLB标为本轮整图导出。
- 仍是有限一轮模块化场景精化：布罩为低模折面轮廓，程序化材质与污渍较基础，未完成手工纹理、LOD/碰撞烘焙、性能预算或AAA最终美术验收。
