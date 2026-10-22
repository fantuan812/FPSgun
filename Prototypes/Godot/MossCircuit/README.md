# MOSS CIRCUIT · 苔芯幸存者 v8

原创 Godot 4.6 像素风 arena-survivor 原型。参考“移动避敌、自动攻击、波次升级”的品类结构，不使用《土豆兄弟》的模型、图像、名称或代码。

本版从冻结 v7 复制，保留历史版本。优先修正“攻击图烘焙手枪，其他武器无法真实装配”的结构问题：**空手九帧身体 + 六种独立世界武器 + 主手与三个辅助挂位 + 独立枪口特效**。角色不是四只手，也不是骨骼 IK。共享枪口姿态同时决定武器外观和弹体起点；近身短段与射程裁切是有意的几何调整，不声称旧判定完全不变。详见 [可换装武器与发射几何](docs/MODULAR_WEAPONS.md)。

保留 **6 武器、26 道具、4 武器槽、构筑加权刷新、五种普通敌人与两 Boss**，以及 [此前动作覆盖与本版修正](docs/ACTION_COVERAGE.md)、[六种像素 VFX](docs/PIXEL_VFX.md)、[装备刷新](docs/SHOP_AFFINITY.md)、[道具机制](docs/MECHANISMS.md)、[敌人/Boss](docs/ENEMIES_AND_BOSSES.md)、[经济](docs/BUILD_SYSTEM.md) 和 [UI](ui/README.md)。本批没有假称所有敌人都新增独立原画，没有增加音频、存档或联网。

所有分包请按 [合并解压说明](docs/DELIVERY.md) 放到同一父目录；完整单包直接解压。

## 运行

1. 安装 Godot 4.6 标准版（非 .NET 即可）。本次实际版本为官方 **4.6.3**。
2. 解压后在 Godot 项目管理器选择 `project.godot`，导入后按 F6/F5，或者命令行 `godot --path .`。
3. 标题界面输入整数 seed，然后 START SALVAGE。

这是**可导入的完整源码工程**，不是 Windows 安装包；没有运行 Windows 导出或真人操作验收。UI 暂为英文以避免系统中文字体依赖，中文说明见本文。

- WASD / 方向键：移动；自动瞄准最近敌人发射。
- Space：短距离冲刺，2.5 秒冷却，冲刺期间免疫接触伤害。
- 标题/暂停的 DISPLAY SETTINGS：降低受击提亮与特效透明度，仅会话内生效。
- Esc：暂停/恢复；I：查看构筑/关闭背包；鼠标点击或数字 1/2/3 选升级。
- 波间商店：购买、刷新、单件出售、满槽选择替换；替换会丢弃旧武器无返款。Tab/方向键切焦点、Enter 激活，长列表可滚动。
- 六波，每波至少 30 秒（Boss波还需击杀Boss）；波间回收地面经验、修复 15 HP 并选择一项升级。
- 经验升级也有三选一；死亡重开可保留同 seed 或换下一个 seed。
- 六种升级：伤害、移速、射速、装甲、吸取范围、穿透。五种普通敌人：追踪、冲锋、远程、侧袭、召唤；波3/6有两阶段Boss。

## 实际范围

- `data/balance.json`：角色、敌人、地图、波次、升级数据。
- `scripts/rules.gd`：可独立验证的升级、选择、地图规则。
- `scripts/main.gd` / `scenes/main.tscn`：run 生命周期、战斗、UI 与场景组装。当前仍是垂直切片，不声称大型项目架构已完成。
- `scripts/art.gd`：九帧 SpriteFrames、AtlasTexture 切片与枢轴补偿。
- 地图目前随机化的是 **9 种可行走地表方块的排列**；没有随机障碍拓扑、房间连通、NavMesh 或寻路。竞技场连续可走，边界限制玩家。
- 同 seed 保证相同版本内地表布局及独立 RNG 的初始序列；输入/帧时间会改变战斗过程，不是跨版本 deterministic replay。
- 没有存档、局外永久成长、联网、声音/音乐。局内构筑与胜负闭环可运行，难度和平衡未经真人实玩。

## 九帧美术管线

见 [美术管线](docs/ART_PIPELINE.md)。累计通过内置 image_gen 实际生成并使用：

1. 主角 walk，3×3 共 9 个有腿部位移的连续帧。
2. 甲虫 walk，3×3 共 9 个连续帧。
3. 3×3 共 9 种地面方块。
4. v3 新增六张敌人/Boss九帧图，甲虫沿用原图，共七种；见 [角色美术与限制](docs/art/enemies/README.md)。
5. v4 新增8个机制道具图标，合计24个装备图标（4武器+20道具），见 [v4图标说明](docs/art/mechanism_icons.md)。
6. v6 新增六张3×3九帧特效（54帧），见 [动画特效](docs/PIXEL_VFX.md)。
7. v5 新增独立8图标（2武器+6道具），旧24图标逐字节保留；见 [新增图标](docs/art/build_expansion_icons.md)。
8. v2 新增 4×4 装备图标：4 武器 + 12 道具，商店、背包与升级界面已使用；见 [图标来源与检查](docs/art/README.md)。
9. v7 六套身体/Boss 动作；本版主角攻击被空手版本替换，旧图仅历史。
10. v8 空手九帧攻击与六种独立世界武器 PNG，见 [装配素材](docs/art/weapon_mounts/README.md)。原有带环境光晕的 atlas 留作 provenance，不再被运行时 manifest 加载。

idle 暂复用 walk 第一帧；弹丸/经验/判定轮廓保留简单代码绘制，六主题事件特效已使用九帧PNG动画。**不是“所有动作都已制作九帧”**。原PNG未经重绘、缩放或抠图；Godot 中以纹理区域与透明边距处理帧不整齐问题。

## 验证

`godot --headless --path . --script tests/test_game.gd`

若云环境默认 HOME 不可写，用独立可写路径：

```bash
mkdir -p /tmp/moss-home /tmp/moss-config /tmp/moss-data /tmp/moss-cache
HOME=/tmp/moss-home XDG_CONFIG_HOME=/tmp/moss-config XDG_DATA_HOME=/tmp/moss-data XDG_CACHE_HOME=/tmp/moss-cache \
  godot --headless --path . --script tests/test_game.gd
```

这不会写用户真实存档；临时测试和初始化只在上述目录写 Godot 缓存。首次导入可以先 `godot --headless --editor --path . --import --quit`，沿用这些环境变量。

本版最终 clean headless 导入及全部 **20 个脚本通过**，作者装配 159 项、独立装配/几何 217 项及完整旧回归；最终六单图与实际挂点已进入测试。见 `docs/validation/independent-v8/`。仅有导入与行为/矩阵验证，没有窗口实玩。

历史 v1–v7 日志保留。v7 clean headless 导入及全部 18 个脚本通过：作者动作 114 项、独立动作 35 项及完整旧回归。结果见 `docs/validation/independent-v7/`。

历史 v6：v6六类真实特效加载共54帧，作者161项表现层检查及独立130项检查通过，包含逐帧边界、固定锚点/scale、链电端点、回收池、暂停重开、伤害/RNG隔离及预警层级。旧全套玩法、经济、敌人、构筑与UI回归继续通过（193/11/213/28/72/25/20/109/133/35/565/216/26及UI结构）。600帧headless smoke通过。详细证据见 `docs/validation/independent-v6/`，历史结果在对应子目录。

自动测试覆盖有限 seed/升级、九帧区域/统一画布/脚底枢轴、动画速度缓存、场景启动/射击击杀/升级重复点击/六波胜利/死亡重开。日志见 `docs/validation/`（v1 历史保留在子目录）；不要只看进程退出码，Godot 某些脚本解析错误也会返回 0，应同时核无 SCRIPT ERROR/ERROR 且出现通过汇总。

窗口运行与屏幕截图 **BLOCKED**：本云环境 Xorg 无法建立本地监听 socket；一次正常提权启动也在沙箱挂载阶段失败。未绕过权限，未伪造游戏截图。headless 规则通过不等于视觉、手感、性能或 Windows 验收。

## 修改与后续

可在有效范围内修改 balance 数据：arena 宽高至少 48、tile_size 必须大于 0；waves 与 max_enemies 为正整数、波时长/生成间隔为正数，升级 id 与字段须保持代码约定。本原型不提供任意 JSON 的运行时校验器。添加新的动作时按美术说明生成新九帧 sheet，先检查每帧轮廓/脚底，再登记 alpha 元数据；不要将新动作9张不同立绘当连续动画。下一批优先：真实窗口实玩与截图、构筑经济平衡、普通敌人与 Boss 各自的受击/死亡原画、挂点与遮挡的真实窗口微调、随机障碍连通验证、声音。

## 检查入口

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_builds.gd
godot --headless --path . --script tests/test_encounters.gd
godot --headless --path . --script tests/test_effects.gd
godot --headless --path . --script tests/test_expansion.gd
godot --headless --path . --script tests/test_weapon_mounts.gd
godot --headless --path . --script tests/independent_weapon_rig.gd
godot --headless --path . --script tests/test_actor_actions.gd
godot --headless --path . --script tests/independent_actions.gd
godot --headless --path . --script tests/test_vfx.gd
godot --headless --path . --script tests/independent_vfx.gd
godot --headless --path . --script tests/independent_shop.gd
godot --headless --path . --script tests/independent_v5.gd
godot --headless --path . --script tests/independent_v4.gd
godot --headless --path . --script tests/independent_qa.gd
godot --headless --path . --script ui/test_ui.gd
godot --headless --path . --script tests/independent_v2.gd
godot --headless --path . --script tests/independent_v3.gd
godot --headless --path . --script tests/independent_enemy_ui.gd
godot --headless --path . --script tests/independent_ui.gd
godot --headless --path . --script docs/art/check_icons.gd
```

云环境同样需要上文可写 HOME/XDG。headless UI 布局/信号测试不等于渲染截图或真人可用性验收。
