# 人物尺度依据与检验边界

- Epic 官方 UE 5 第三人称模板文档区分 Quinn、Manny 与旧版 UE4 mannequin，但没有给出 Manny 网格精确身高表。不能把常见的 180 cm 说法当成本项目实测。
  https://dev.epicgames.com/documentation/en-us/unreal-engine/third-person-template-in-unreal-engine
- Epic 官方多人编程入门使用 C++ 第三人称模板，示例构造中 `InitCapsuleSize(42.f, 96.0f)`。这给出半径 42 cm、半高 96 cm，即总高 192 cm 的示例碰撞胶囊，不是网格身高，也不能排除特定 Blueprint 的覆盖。
  https://dev.epicgames.com/documentation/en-us/unreal-engine/multiplayer-programming-quick-start-for-unreal-engine
- CapsuleComponent 参数为 radius 与 half-height；半高包括端部半球，未缩放尺寸不含组件变换。
  https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/CapsuleComponent?application_version=5.6
- 官方关卡搭建教程采用厘米（100 cm = 1 m）并建议放置 SKM_Manny_Simple 作比例参照。
  https://dev.epicgames.com/documentation/en-us/unreal-engine/designer-01-project-setup-and-level-blockout-in-unreal-engine

本批次使用高 **2.10 m、半径 0.50 m** 的保守检查代理，比上述官方示例胶囊更大。其不是已导入/测量的官方 Manny 模型。Blender 的单位设为米；原核心位置和尺度保持不变。已有核心设备区/窄环不得仅凭本批次通路抽样宣称全区适配。眼高 1.65 m 是展示视角，不是角色身高。

静态几何采样不等同于 UE 胶囊扫掠、CharacterMovement、导航、楼梯运行或实际战斗测试。掩体间距 8–12 m、连续无遮蔽段超过 20 m 提修仅为本图设计目标，并非官方规范或用户给定数值；遮蔽视线检查不能保证战斗安全。
