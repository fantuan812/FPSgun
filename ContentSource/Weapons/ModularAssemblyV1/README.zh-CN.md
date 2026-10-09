# FPSgun 三平台模块化视觉资产 v1

这是可编辑游戏美术资产与装配挂点数据，配合 FPSAssembly 运行时系统。不是现实武器制造CAD、内部机构或实枪装配指导；所有坐标仅用于虚拟物件。

## 三个平台与共享模块

- KITE01：复用原枪体外观，8个平台件
- WISP02：新建冲锋枪轮廓，8个平台件；护木带实际几何凹槽
- MOTE03：新建手枪轮廓，4个平台件；上部外壳、弹匣、扳机可独立动画
- 5共享件：reflex瞄具、micro瞄具、universal→micro外观转接件、灯、短握把

总计25个稳定module ID。5个共享件共用同一模型定义，装配实例引用它们，而不是为每把枪复制一套数据定义。core/弹匣等平台件保留平台身份。

## 持久文件

- AetherLab_ThreePlatform_Modular.blend：压缩原生场景，25件源库与7套装配fixture
- inputs/KITE01_Source.blend：确切旧枪源输入，纯枪体，不含CHR01角色迁移
- exports/modules/：25个独立GLB，入口枢轴在模块原点
- exports/：7套组合GLB，实际按挂点树组合
- textures/：自制PBR基础色/粗糙度，金属度为标量
- config/Visual_Module_Manifest.json：视觉ID、模块、挂点、完整旋转和平移、组合树
- reference/ThreePlatform_Concept.png：生成的目标概念；renders/*.png是实际Blender图，不能混淆

本批应把实际blend/GLB/纹理/图片随仓库提交，Library仅用于聊天递送副本，不能以Library身份代替仓库二进制。每个大附件单独或按小于8MiB独立ZIP交付；保存不等于发送，accepted也不等于用户已打开。

## 装配关系

步枪/冲锋枪core的universal optical槽可接reflex或转接件。转接件再提供micro槽，形成真实三层父子变换。手枪slide自身提供micro槽。护木under_light与under_grip共享占位token，不能同时装；WISP额外side_light为独立占位，可与下短握把共存，其挂点旋转为-90°绕局部X。

稳定ID、transform与视觉分件是本目录职责；正式compatibility、依赖/互斥、容量、循环、事务、属性、存档和非法组合拒绝由FPSAssembly系统定义/执行，不能把Blender的可视fixture装配器当gameplay。正式数据转换会读取本manifest，具体规则验收以系统文档和测试结果为准。

## 坐标和动画边界

源为Blender右手米制，+X前、+Z上；rotation_xyzw明确XYZW；模块入口原点为(0,0,0)，slot是父module本地坐标。完整链为parent_world × slot_local × module_local。

UE使用厘米且手性不同，必须进行Y轴反射与相应旋转变换，不能只乘100。具体镜像矩阵/转换由系统导入边界处理。engine_soft_reference=null表示尚无已导入的uasset，不是缺失值可随意猜路径。

手枪slide、各平台弹匣/扳机、步枪及冲锋枪拉柄均独立，提供后续动画入口。本批7组合为静态，不称已完成开火、第一人称瞄准、抵肩、角色手指贴合或完整换弹；没有迁移角色源到FPSgun。

## 重建

在本目录中依次执行：

blender -b --python source/build_platform_assets.py
blender -b --python source/extend_side_mount.py
blender -b --python source/render_comparison_board.py
blender -b --python source/verify_visual_assemblies.py

第二步在六套基础组合上加入带非identity旋转的第七套侧灯组合。重建会覆盖同名生成输出；请在拷贝目录进行，勿覆盖手工编辑原件。

## 验证范围与美术差距

Blender实测记录见docs/Blender_Visual_Validation.json，包含模块网格与UV、入口枢轴、完整树变换残差、GLB回读以及模块间有限三角表面交叉。接头有意重叠、弹匣可见/隐藏插入区和封闭嵌套不等于可见穿帮；三角相交数也不是穿入深度，未证明连续运动无碰撞。视觉结论另外列明实际查看的图片。

概念图是更写实的目标，当前为干净、较方正的游戏美术首版，尚无高模烘焙法线、精细磨损、专用第一人称网格与完整LOD优化。本批不能叫最终AAA美术验收。

UE编译、启动、导入验收未运行，用户已取消UE验收。Blender结构结果、系统纯逻辑测试和UE运行是三种不同证据，不相互替代。
