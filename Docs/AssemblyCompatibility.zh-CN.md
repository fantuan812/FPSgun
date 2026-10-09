# 静态兼容契约与待运行夹具

本表来自正式定义与视觉源数据的静态对照，**不是运行权威validator产生的通过报告**。最终接受仍由同一Core算法执行整树、依赖、占位、容量、锁定/绑定和版本检查；mount类型相等不等于整个请求合法。

## 平台与槽位

| 父模块/槽位 | 接受部件 | 共享或专属 | 可用性/占位 |
|---|---|---|---|
| kite01.core的handguard.standard/stock.standard/grip/magazine/muzzle/charging_handle/trigger | 对应kite01同名定义 | kite01专属 | 必需；每槽1件 |
| wisp02.core的同组槽位 | 对应wisp02同名定义 | wisp02专属 | 必需；每槽1件 |
| mote03.core的slide/magazine/trigger | 对应mote03同名定义 | mote03专属 | 必需；每槽1件 |
| kite01.core或wisp02.core / optic | shared.optic.reflex 或 shared.adapter.universal_micro | 两个平台共享 | 可选，互占optic |
| shared.adapter.universal_micro / micro | shared.optic.micro | 跨平台转接 | 可选，子槽深度+1 |
| mote03.slide / optic | shared.optic.micro | 原生micro | 可选，不需要universal转接 |
| kite01/wisp02 handguard.standard / under_light | shared.light.compact | 共享 | 与同父under_grip共用under_shared |
| kite01/wisp02 handguard.standard / under_grip | shared.grip.stub | 共享 | 与同父under_light互斥 |
| mote03.core / under_light | shared.light.compact | 共享 | 可选，under_shared |
| wisp02.handguard.standard / side_light | shared.light.compact | 共享 | side_utility独立，可与下握把共存 |

不同父实例上同名token互不影响；例如两把枪各装一盏灯不会彼此占位。相同部件定义可有多个库存实例，实例ID不可复用。核心永远不能附到另一个核心的槽。跨平台弹匣即使外观相似也拒绝。

## 七个已交付视觉组合及代码夹具

kite01.compact_optic、kite01.standard、mote03.compact_optic、mote03.standard、wisp02.compact_optic、wisp02.side_light、wisp02.standard。

视觉组合有实际GLB与渲染；同名DTO和C++夹具已准备，**未运行Core/UE**。资产报告中的矩阵残差只属于Blender与GLB，不表示运行时API已通过。

## 其他规则的源码夹具

`Tests/AssemblyRulesTests.cpp`覆盖错误core/弹匣、缺少micro转接、灯/握把空间冲突、批量替换、保留全部实例、旧revision、锁/绑定的子树保护、未知parent/slot、重复编辑、无效存档边、无环/深度/容量、必需槽的“可编辑但不可用”边界、非有限属性拒绝以及确定性统计。

正式25定义目前 `requires_all/excludes_any` 为空，七个视觉组合依靠mount类型和占位约束。依赖/排除的通用能力在独立数据-only夹具中展示：为reflex增加requires_all=fixture.provider，缺提供者拒绝；仅给core增加对应标签就可满足；再为reflex增加excludes_any=platform.kite01则拒绝。不编造视觉资源尚不存在的配件限制，也不把未执行夹具当成功证据。

## 未覆盖的产品功能

UI拖拽/树形检查器、网络请求幂等账本、交易/掉落/背包格子守恒、实际GAS技能授予、射击和弹药消费、第一人称动画、声音和Niagara内容、原生uasset/Cook、生产网络/存储故障与性能验收均需宿主集成。此插件提供装配规则及其UE/数据/展示边界，不能称整个塔科夫式游戏已完成。
