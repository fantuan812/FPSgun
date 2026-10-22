# v6 解压与运行

两包都需要：

1. 把 `MossCircuit-v6-01-Project.zip` 与 `MossCircuit-v6-02-AnimationArt.zip` 解压到**同一个父目录**。
2. 合成同一个 `MossCircuit-v6` 文件夹。第二包包含敌人/Boss及六主题特效PNG，不能单独运行；不要在第一包内部再嵌套一层目录。
3. 确认 `MossCircuit-v6/project.godot`、`MossCircuit-v6/assets/enemies/boss_core.png` 和 `MossCircuit-v6/assets/vfx/explosion.png` 同时存在。
4. 用 Godot 4.6 标准版导入 `project.godot`，等待资源导入，按F5。

完整单包 `MossCircuit-v6-PixelVFX-2026-10-22.zip` 直接解压即可，无需另外合并分包。

两分包没有重叠路径，合并后逐文件与完整单包一致，根目录 `MANIFEST.json` 保存校验。不要覆盖旧v1–v5目录。源码工程不是Windows安装包，需要Godot；未做Windows导出和真人窗口验收。
