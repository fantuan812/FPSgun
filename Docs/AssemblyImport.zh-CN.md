# UE接入与可重复作者流程（本批未执行）

## 前提与状态

此仓是插件/资产交付仓，不含完整 `.uproject` 或 AetherLab。复制 `Plugins/FPSAssembly` 到既有UE项目；让宿主模块声明FPSAssembly依赖。目标引擎由宿主锁定，本批没有UE编译、UHT或编辑器验证，因此API/Importer差异可能需要调整。

启用Editor Python、项目支持的GLB/Interchange导入器。Runtime插件依赖Engine、GameplayTags、Niagara；不依赖GAS，宿主适配战斗。插件启动时载入Config/Tags下的明确标签；若作者新增标签，需添加到该文件并在编辑器重启/刷新后再创建定义。

## 数据与模型映射

- `Data/AssemblyCatalog.json`：正式作者定义，25 part ID映射到实际repo的`source_mesh_glb`
- `ContentSource/Weapons/ModularAssemblyV1/config/Visual_Module_Manifest.json`：视觉源契约，包含parent-local米制挂点、入口和组合
- `Data/Presets/*.json`：7个codec v1实例/装配树示例，可作为独立测试库存；生产不能不经权威库存流程授予给玩家
- `Scripts/GenerateAssemblyData.py`：由视觉清单重生成示例作者数据与tag配置。本批已执行数据生成，**没有执行规则校验**。手工调优正式定义后不要无差别覆盖，可另存产品内容定义
- `Scripts/GenerateFixtureHeader.py`：从正式数据生成C++夹具常量；本批仅生成，不执行夹具

同机制新增武器可直接新增定义DataAsset或作者JSON、对应标签、实例种子与模型映射，不需要修改core算法或Character中的枪名分支。样例数据生成脚本是bootstrap作者工具，并非生产运行时注册限制。

## 两阶段导入，先验证实际资源再写软引用

在UE编辑器Python把本仓`Scripts`加入Python模块搜索路径，然后import `ImportAssemblyAssets`。它提供两个函数，**本批均未执行**：

1. `import_meshes(repo_root, destination, report_path)`
   - destination选新 `/Game/` 路径；先检查全批合法ID及点/横线归一化后的名字碰撞，再逐模块隔离文件夹，拒绝覆盖已有文件夹
   - 从正式ID映射读取真实GLB，检查导入返回的真实UStaticMesh；只接受每模块恰好一个静态网格
   - 写出实际资产object path、来源SHA与catalog SHA报告，所有basis_verified初始false
   - 不猜Importer版本行为；失败可能留下已新建的部分资源，检查后处理，不掩盖成“完整成功”
2. 在编辑器实查模型米→厘米尺度、入口枢轴、+X/+Z方向、Y反射以及wisp侧灯源-90°X目标姿态，比较正式父local变换组合与参考图。注意：视觉manifest是Blender右手Z-up，GLB本身经export_yup=True导出为glTF Y-up中间格式。必须先由实际Importer还原/转换该格式，再与manifest→UE目标坐标对照；不能直接把manifest的反射公式施加到原始GLB buffer，也不能重复反射。确认每模块实际导入基变换后才将该行basis_verified置true
3. `author_definitions(repo_root, reviewed_report_path)`
   - 验证report与当前源文件/定义的SHA对应、25 ID完整且无重复、真实StaticMesh可读取、basis已确认
   - 通过同一native JSON parser/Compile创建临时定义，再生成并保存真实PrimaryDataAsset/Catalog，不在Python实现另一套兼容规则
   - 仅使用实际导入返回的object path写软引用，拒绝覆盖已有数据资产
   - 返回真实catalog object path。只有该阶段实际成功后才能称 `.uasset` 已创建

脚本尚未经UE执行，因此不能承诺某个引擎版本的Python返回值/导入factory无需修改。若UHT或API报错，在宿主固定版本修正后重新预检；不要在本仓填写猜测路径来绕过空引用。

## 运行时宿主对接

1. 权威Actor配置`UFPSAssemblyComponent.Catalog`（所有客户端使用相同已导入catalog版本）
2. 用`FPSAssemblyCodec::Decode`读取已持久库存DTO；验证成功后由服务端可信库存所有者`RestoreCommitted`
3. 绑定CommitCandidate到既有库存事务，校验expected revision并持久保存完整候选；返回true后组件才公布
4. 玩家请求通过既有服务端命令/身份授权/幂等入口调用TryApply；不能让客户端指定Owner或调用可信恢复
5. 使用ValidateReady/IsReady检查必需槽；由宿主把EvaluateStats结果映射到原有GAS来源效果，并负责移除旧来源
6. 已提交装备选择调用SelectPresentation(root)，公开只读快照随Actor复制；远端`UFPSAssemblyVisuals.BindPresentation`只看选中树。私有库存预览使用Bind(source, root)
7. 把Visuals场景组件附到已存在、独立确认的角色握持入口。本批不更换角色，不假定骨轴，不制作完整第一/第三人称动作

## 验证入口及当前结果

仅在代码/资产实现完成、进入统一验证阶段后：

- Standalone：`cmake -S Tests -B <outside-repo-build>`、构建、ctest；包含7组合、错误弹匣/core、转接嵌套、占位、缺槽、循环、容量、未知引用、锁绑定、事务失败输出不污染、修正汇总
- UE：编译插件/UHT；执行`FPSAssembly.Codec.AtomicRoundTrip`；再用真实服务器库存夹具故障注入提交失败/重试/恢复，检查无经济复制
- UE双客户端：远端公开树、owner私有字段、晚加入、同revision装备选择、异步加载完成先后、卸载销毁、缺网格、取消
- UE实际资产：导入三平台、7组合与非identity侧灯，逐帧确认挂点/材质、碰撞/LOD与操作交互；资产目前没有制作成可用完整FPS射击流程

当前纯C++规则已通过直接GCC构建（CMake未安装，因此未跑CMake/CTest入口）；纯Python命名预检也通过。UE codec及本页所有UE步骤仍未运行。没有CI配置自动代替它们；无CI结果不能解释为“全部通过”。
