# v5 解压与运行

若下载两包：

1. 将 `MossCircuit-v5-01-Project.zip` 与 `MossCircuit-v5-02-EnemyArt.zip` 都解压到**同一个父目录**。
2. 两包会合成同一个 `MossCircuit-v5` 文件夹。第二包只有新敌人/Boss PNG；不能单独运行，也不要放进第一包内部再次套一层目录。
3. 检查 `MossCircuit-v5/assets/enemies/boss_core.png` 和 `MossCircuit-v5/project.godot` 均存在。
4. 用 Godot 4.6 标准版导入 `project.godot`，等待资源导入，按 F5。

若下载完整单包 `MossCircuit-v5-BuildAffinity-2026-10-22.zip`，直接解压即可，无需另解两份小包。

两小包文件路径不重叠，合并内容与完整单包一致，均由项目根 `MANIFEST.json` 校验。不要覆盖旧v1–v4目录。源码项目不是Windows独立安装包，仍需要Godot。
