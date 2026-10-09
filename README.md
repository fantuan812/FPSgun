# FPSgun

数据驱动的虚构游戏枪械与模块化配件装配，供 Unreal Engine 项目集成。

## 本批交付

- `Plugins/FPSAssembly`：C++装配规则、UE PrimaryDataAsset/GameplayTags、实例与显式存档DTO、事务提交适配、私有库存与公开装配投影复制、只读异步外观组件
- `Data`：25定义、7套装配实例示例。JSON不是uasset；当前mesh引用为空
- `ContentSource/Weapons/ModularAssemblyV1`：三平台原生Blender场景、25模块与7组合共32GLB、纹理、渲染和Blender限定验证记录（资产来源PR #2）
- `Tests`：纯C++规则夹具；UE codec夹具在插件Private/Tests
- `Scripts`：作者数据/夹具生成及待执行的两阶段UE导入脚本

## 阅读顺序

1. [架构、单一权威、事务与多人展示边界](Docs/AssemblyArchitecture.zh-CN.md)
2. [静态兼容矩阵与待运行夹具](Docs/AssemblyCompatibility.zh-CN.md)
3. [UE导入、实际资源映射与宿主接入步骤](Docs/AssemblyImport.zh-CN.md)
4. [静态审阅记录](Docs/AssemblyStaticReview.json)

## 执行与验收边界

先完成代码和必要资产，再统一编译、测试与修复。实现期间不运行编译、规则测试或启动测试；每批提交记录真实验证状态。

2026-10-09经用户批准进入统一纯C++验证：GCC 14.2.0严格警告编译、装配规则夹具与ASan/UBSan（关闭泄漏检测）通过；7个纯Python命名预检用例通过。精确命令/退出码/限制见[验证报告](Docs/Validation/PureCppValidation.json)。**UE/UHT/PIE、引擎编译与导入仍未执行**。源码、可编辑模型、交换格式、UE原生资产与引擎验收分别记录；不把JSON/GLB称为已导入uasset，不宣称已完成引擎集成或实际射击玩法验收。当前没有完整uproject、宿主库存数据库/命令/UI/GAS接入或已导入的mesh软引用；动画/Niagara为引用接口，内容与播放流程尚未完成。

仅制作游戏外观与游戏规则，不提供真实武器制造、改装或内部工艺说明。模型许可和来源见资产目录的Sources_Licensing.md；不擅自授予第三方资源额外许可。
