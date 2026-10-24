# MOSS CIRCUIT · 苔芯幸存者 v14 · 守门者反应层

本版从已发布v13 commit `56a6c721850fc3ef67caa0f766661a3970eb6a59` 延续，只补现有Wave3守门者的 **hurt9帧/0.27秒与death16帧/0.72秒**。不新增Boss或招式、不改攻击/伤害/AI/移动/RNG；旧charge/blast通用attack九帧仍保留其限制。详情见 [守门者反应层合同](docs/WARDEN_REACTIONS.md)。

## v13 恢复记录（历史）



本版从 GitHub v12 commit `6d393134da0a29a7c62a821abf50440e6d304f25` 的 699 个文件逐 Git blob SHA 校验恢复后重建，不冒充遗失的旧 v13 工程原包。新增 crawler/flanker 各受击9帧（0.27秒）与死亡16帧（0.72秒）；四张 PNG 源字节由原 Git blob 恢复，裁片 manifest、集成与验收在 2026-10-24 重新制作/运行。九帧不是动作上限，详见 [接触型敌人动作合同](docs/CONTACT_ENEMY_ACTIONS.md)。

修正：追踪/侧袭怪距离玩家85以内仍在移动，表现不再凭距离伪造 warning、停播 walk 或压缩身体。只删除 ActorDirector 的两行表现分支；移动、接触伤害、奖励、AI 与随机数不改变。真实接触的程序化攻击脉冲保留，没有新增可躲避攻击前摇。

原创 Godot 4.6 像素风 arena-survivor 原型。参考“移动避敌、自动攻击、波次升级”的品类结构，不使用《土豆兄弟》的模型、图像、名称或代码。

v12 基于已发布 v11，**补召唤者 Moss Broodkeeper 的召唤16帧、受击9帧、死亡16帧**。九帧只是方便生图的批次，不是动作上限；长动作改为单张4×4，短受击保留9帧。ActorDirector按真实剪辑长度播放，不改变AI/伤害/生成/经济/RNG。原0.65秒预警之后的释放帧表示“召唤尝试”，不是无条件保证出怪：3只活子体或全局上限满时可新增0只；随后按原0.7秒恢复推进。受击不拖延或补播召唤，父体死亡不会凭动画杀掉既有子体。见 [召唤者动作合同](docs/BROODKEEPER_ACTIONS.md)。

v11 Spitter 的射击/受击/死亡及其真实同tick发弹合同完整保留，见 [远程敌人合同](docs/SPITTER_ACTIONS.md)。

v10 冲锋者的蓄力/冲锋/恢复、受击、死亡九帧与已校准接地关键帧完整保留，见 [冲锋者合同](docs/CHARGER_ACTIONS.md)。

v9 已完成的共享战斗/构筑与模式策略继续保留：原 Arena 和 3 房间有限遭遇原型使用同一套战斗，支持受控测试的非相邻推进/不开店结算；仍不是完整地牢。见 [架构与模式合同](docs/ARCHITECTURE_AND_MODES.md)。

v8 的空手九帧身体、六种独立世界武器、主手与三个辅助挂位、独立枪口特效完整保留；[装配与共享发射几何](docs/MODULAR_WEAPONS.md) 不回退成烘焙手枪。
保留 **6 武器、26 道具、4 武器槽、构筑加权刷新、五种普通敌人与两 Boss**，以及 [此前动作覆盖与本版修正](docs/ACTION_COVERAGE.md)、[六种像素 VFX](docs/PIXEL_VFX.md)、[装备刷新](docs/SHOP_AFFINITY.md)、[道具机制](docs/MECHANISMS.md)、[敌人/Boss](docs/ENEMIES_AND_BOSSES.md)、[经济](docs/BUILD_SYSTEM.md) 和 [UI](ui/README.md)。本版补齐五种普通敌人的独立受击/死亡图；crawler/flanker 接触攻击仍为程序化表现，两 Boss 的独立受击/死亡仍未补齐，没有增加音频、存档或联网。

所有分包请按 [合并解压说明](docs/DELIVERY.md) 放到同一父目录；完整单包直接解压。

## 运行

1. 安装 Godot 4.6 标准版（非 .NET 即可）。本次实际版本为官方 **4.6.3**。
2. 解压后在 Godot 项目管理器选择 `project.godot`，导入后按 F6/F5，或者命令行 `godot --path .`。
3. 标题界面选择 ARENA SURVIVAL 或 ROOM ENCOUNTERS，输入整数 seed，然后 START SALVAGE。只有标题允许切换模式；切换保留当前输入 seed，新局不会继承上局构筑。

这是**可导入的完整源码工程**，不是 Windows 安装包；没有运行 Windows 导出或真人操作验收。UI 暂为英文以避免系统中文字体依赖，中文说明见本文。

- WASD / 方向键：移动；自动瞄准最近敌人发射。
- Space：短距离冲刺，2.5 秒冷却，冲刺期间免疫接触伤害。
- 标题/暂停的 DISPLAY SETTINGS：降低受击提亮与特效透明度，仅会话内生效。
- Esc：暂停/恢复；I：查看构筑/关闭背包；鼠标点击或数字 1/2/3 选升级。
- 波间商店：购买、刷新、单件出售、满槽选择替换；替换会丢弃旧武器无返款。Tab/方向键切焦点、Enter 激活，长列表可滚动。
- Arena：六波，每波至少 30 秒（Boss 波还需击杀 Boss）；波间回收地面经验、修复 15 HP 并选择升级。
- Rooms：三份有限敌群计划，必须清完计划和所有召唤子体；清场安全过渡 0.6 秒，再升级/商店或终局。没有门交互或迷宫探索。
- 经验升级也有三选一；死亡重开可保留同 seed 或换下一个 seed。
- 六种升级：伤害、移速、射速、装甲、吸取范围、穿透。五种普通敌人：追踪、冲锋、远程、侧袭、召唤；波3/6有两阶段Boss。

## 实际范围

- `data/balance.json`：角色、敌人、地图、波次、升级数据。
- `scripts/rules.gd`：可独立验证的升级、选择、地图规则。
- `scripts/gameplay/`：独立角色、战斗、武器/效果、运行状态与结算；`scripts/modes/`：Arena 和有限房间策略；`data/room_encounters.json`：受预算校验的房间计划。
- `scripts/main.gd` / `scenes/main.tscn`：组合层、输入/UI 接线、视觉实体工厂与模态生命周期。尚非通用地牢框架。
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
9. v7 六套身体/Boss 动作；v8 主角攻击被空手版本替换，旧图仅历史。
10. v8 空手九帧攻击与六种独立世界武器 PNG，见 [装配素材](docs/art/weapon_mounts/README.md)。原有带环境光晕的 atlas 留作 provenance，不再被运行时 manifest 加载。

v9 房间 HUD 候选图没有通过去环境光晕验收，隔离存入 `art_source/v9-room-candidates/`，默认使用代码像素锁/勾，未把失败图当运行素材。

11. v10 冲锋者三张九帧（27 帧），见 [素材来源与源图限制](docs/art/charger/README.md)。death 首两帧已显式校准接地裁片窗口；PNG/统一尺度不改，仍未做 GUI 整合验收。

12. v11 Spitter 射击、受击、死亡三张九帧（27帧）已通过源图目视/结构门槛并接入，见 [来源与限制](docs/art/spitter/README.md)。它们是高分辨率像素风sprite，并非严格原生低分辨率逐像素动画；最终全回归结果见验证节。

13. v12 Broodkeeper 召唤16帧、短受击9帧、死亡16帧（共41真实姿态）已通过源图/裁片/透明padding检查并接入。长动作单张4×4，九帧不是动作上限；死亡原序列回站问题已用显式作者播放顺序修正，未改PNG或逐帧缩放。见 [新素材来源与边界](docs/art/brood_keeper/README.md)。

idle 暂复用 walk 第一帧；弹丸/经验/判定轮廓保留简单代码绘制，六主题事件特效已使用九帧PNG动画。**不是所有动作都已补齐，也不要求所有动作只有九帧**。原PNG未经重绘、缩放或抠图；Godot 中以纹理区域与透明边距处理帧不整齐问题。

## 验证

**v14守门者反应层（2026-10-24）：**删除生成缓存后cold headless导入与44个测试入口全部通过；作者38项、独立942项，旧动作精确ID/帧数回归314项。159个旧权威/配置/资产/UI/场景字节不变，runtime `.gd` 零修改。见[工程报告](docs/validation/v14-warden/QA_REPORT.md)及[独立报告](docs/validation/independent-v14-warden/QA_REPORT.md)。下列v13及更早均为历史结果。没有GUI或Windows导出验收。

**v13 恢复重建（2026-10-24）：**当前最终metadata下 clean headless 导入 + 42个测试入口全部通过，日志无ERROR；包括旧36个测试、新作者/独立接触敌人测试、UI与3个图标检查。140个v12旧权威/配置/资产字节不变；新素材manifest可由源码分析脚本逐字节重现。见 [本次工程报告](docs/validation/v13-rebuild/QA_REPORT.md) 与 [本次独立报告](docs/validation/independent-v13-rebuild/QA_REPORT.md)。以下v12及更早结果仅是历史。GUI与Windows导出未运行。

v12 修订后真正 clean headless 导入，**37 个入口全部通过**：旧33、作者229项、独立610/66/374共1050项。221个已测运行输入前后及干净副本hash一致；142个旧权威/配置/资产原字节不变。仅ActorDirector表现层泛化真实帧数与安全透明padding，不改AI/伤害/生成/RNG。见 [v12独立报告](docs/validation/independent-v12/QA_REPORT.md)。旧九帧候选及死亡顺序修正前的结果未冒充本版证据；GUI/Windows未运行。下列保留历史版本结果。

v11 已真正 clean headless 导入，**33 个入口全部通过**：旧29入口、作者162项、独立608/50/199共857项。206个已测运行输入与独立快照前后hash完全一致；另核3个独立脚本。136个旧运行脚本/权威配置/资产保持原字节。见 [v11独立报告](docs/validation/independent-v11/QA_REPORT.md)；GUI/Windows实玩仍未运行。以下各版结果保留为历史证据。

v10 接地关键帧修订后重新 clean headless 导入与 **29 个入口全部通过**：旧 25 个、作者冲锋动作 130 项、独立权威状态 parity/生命周期/资源 366+30+194 项；191 个已测运行输入 hash 一致，见 [最终独立报告](docs/validation/independent-v10/QA_REPORT.md)。旧动作资源计数断言改为精确批准 ID 集合，其余旧断言保留，原 6 动作和旧资源不改。

v9 真正 clean headless 导入及 **25 个入口全部通过**：旧 20 个、作者模式 70 项、独立模式/边界/配置/策略 42+20+109+9 项。170 个运行源码/资源/import 文件与独立测试快照逐字节一致；6 个独立脚本另有 SHA。见 [最终独立报告](docs/validation/independent-v9/QA_REPORT.md)。未运行 GUI/Windows 验收。

`godot --headless --path . --script tests/test_game.gd`

若云环境默认 HOME 不可写，用独立可写路径：

```bash
mkdir -p /tmp/moss-home /tmp/moss-config /tmp/moss-data /tmp/moss-cache
HOME=/tmp/moss-home XDG_CONFIG_HOME=/tmp/moss-config XDG_DATA_HOME=/tmp/moss-data XDG_CACHE_HOME=/tmp/moss-cache \
  godot --headless --path . --script tests/test_game.gd
```

这不会写用户真实存档；临时测试和初始化只在上述目录写 Godot 缓存。首次导入可以先 `godot --headless --editor --path . --import --quit`，沿用这些环境变量。

历史 v8 最终 clean headless 导入及全部 **20 个脚本通过**，作者装配 159 项、独立装配/几何 217 项及完整旧回归；最终六单图与实际挂点已进入测试。见 `docs/validation/independent-v8/`。仅有导入与行为/矩阵验证，没有窗口实玩。

历史 v1–v7 日志保留。v7 clean headless 导入及全部 18 个脚本通过：作者动作 114 项、独立动作 35 项及完整旧回归。结果见 `docs/validation/independent-v7/`。

历史 v6：v6六类真实特效加载共54帧，作者161项表现层检查及独立130项检查通过，包含逐帧边界、固定锚点/scale、链电端点、回收池、暂停重开、伤害/RNG隔离及预警层级。旧全套玩法、经济、敌人、构筑与UI回归继续通过（193/11/213/28/72/25/20/109/133/35/565/216/26及UI结构）。600帧headless smoke通过。详细证据见 `docs/validation/independent-v6/`，历史结果在对应子目录。

自动测试覆盖有限 seed/升级、真实剪辑长度/区域/统一画布/脚底枢轴、动画速度缓存、场景启动/射击击杀/升级重复点击/六波胜利/死亡重开。日志见 `docs/validation/`（v1 历史保留在子目录）；不要只看进程退出码，Godot 某些脚本解析错误也会返回 0，应同时核无 SCRIPT ERROR/ERROR 且出现通过汇总。

窗口运行与屏幕截图 **BLOCKED**：本云环境 Xorg 无法建立本地监听 socket；一次正常提权启动也在沙箱挂载阶段失败。未绕过权限，未伪造游戏截图。headless 规则通过不等于视觉、手感、性能或 Windows 验收。

## 修改与后续

新房间配置的有限数值/类型/4096 格预算见架构文档，非法输入在分配前拒绝。旧 balance 仍须按有效范围修改：arena 宽高至少 48、tile_size 必须大于 0；waves 与 max_enemies 为正整数、波时长/生成间隔为正数，升级 id 与字段须保持代码约定。本原型不提供任意 JSON 的运行时校验器。添加新的动作时按美术说明生成新九帧 sheet，先检查每帧轮廓/脚底，再登记 alpha 元数据；不要将新动作9张不同立绘当连续动画。下一批优先：真实窗口实玩与截图、构筑经济平衡、Boss 独立受击/死亡原画、挂点与遮挡的真实窗口微调、随机障碍连通验证、声音。

## 检查入口

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_modes.gd
godot --headless --path . --script tests/test_brood_actions.gd
godot --headless --path . --script tests/independent_brood_parity.gd
godot --headless --path . --script tests/independent_brood_events.gd
godot --headless --path . --script tests/independent_brood_assets.gd
godot --headless --path . --script tests/test_warden_reactions.gd
godot --headless --path . --script tests/independent_warden_reactions.gd
godot --headless --path . --script tests/test_contact_enemy_actions.gd
godot --headless --path . --script tests/independent_crawler_flanker.gd
godot --headless --path . --script tests/test_spitter_actions.gd
godot --headless --path . --script tests/independent_spitter_parity.gd
godot --headless --path . --script tests/independent_spitter_events.gd
godot --headless --path . --script tests/independent_spitter_assets.gd
godot --headless --path . --script tests/test_charger_actions.gd
godot --headless --path . --script tests/independent_charger_gameplay_parity.gd
godot --headless --path . --script tests/independent_charger_lifecycle.gd
godot --headless --path . --script tests/independent_charger_assets.gd
godot --headless --path . --script tests/independent_modes.gd
godot --headless --path . --script tests/independent_room_boundaries.gd
godot --headless --path . --script tests/independent_policy_validation.gd
godot --headless --path . --script tests/independent_resolution.gd
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
