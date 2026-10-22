# v9 完整工程解压

五个文件都是标准 ZIP，不是 `.001` 分卷：

1. `MossCircuit-v9-01-Project.zip`：代码、配置、旧基础资源、说明及全部验证。
2. `MossCircuit-v9-02-AnimationArt.zip`：累计敌人和六主题 VFX PNG。
3. `MossCircuit-v9-03-ActorActions.zip`：v7 身体/Boss 动作 PNG（旧烘焙主角枪图仅保留历史）。
4. `MossCircuit-v9-04-WeaponMounts.zip`：本版空手动作、六种世界武器及历史 atlas PNG。

5. `MossCircuit-v9-05-RoomCandidates.zip`：隔离的未达标 HUD 原稿与出处（默认运行不加载）。

**五包解压到同一个父目录，合并同名 `MossCircuit-v9` 文件夹。全部解压完才导入 project.godot。** 不要把后续包再解压进已经存在的项目目录而多嵌套一层。五包之间无同路径文件；最终验包确认五包合集逐文件等于完整单 ZIP，包含所有源码和累计资源，并非补丁。

若从 FPSgun 仓库取得已发布完整 `Prototypes/Godot/MossCircuit` 目录，则无需附件步骤，直接导入该目录的 project.godot。完整单包 `MossCircuit-v9-ModeArchitecture-2026-10-22.zip` 也可直接解压。仓库版本以实际发布 commit 为准，源码中的这段说明不是上传成功证明。

`MANIFEST.json` 列出除它自己以外全部交付文件的 SHA-256。工程不包含 `.godot` 缓存或 Godot 引擎二进制。首次导入由本机 Godot 4.6 生成资源缓存。
