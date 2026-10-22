# v9：同一战斗，两个有限模式

本次是可运行的解耦切片，不是通用引擎、插件系统或完整地牢。保留 v8 的六种武器/四槽装配、26 道具、事件来源与防递归、共享枪口几何/近身扫描/射程圆和原 Arena 平衡数据。新模式从标题选择；不能在战斗、商店、升级或结算中换模式。

## 单一数据所有权

| 文件 | 职责/依赖 | 不负责 |
|---|---|---|
| `gameplay/combat_state.gd` | 当前角色派生属性、位置、实体/攻击/掉落容器、战斗时钟 | UI、模式、经济策略 |
| `gameplay/run_session.gd` | 唯一 build、经验等级、阶段、局内状态、奖励账本、UI generation | 绘制、敌人 AI |
| `character_motor.gd` | 输入向量驱动移动/冲刺与伤害算术 | 读取 Input、动画、RNG |
| `weapon_presentation.gd` | 六武器共用静态 pose、实际释放与身体/挂点反馈 | 伤害计算、模式 |
| `weapon_combat.gd` | 发射/散射/近身段/穿透/回旋/射程，引用 world/session/catalog 和表现接口 | 刷怪计划、商店、UI |
| `effect_runtime.gd` | 应用纯 Effects 的事件命令、地带/迫击炮延迟结算 | 模式目标、商店 |
| `combat_context.gd` | 有类型的 world/session/武器/效果引用，以及受伤/生成实体/Boss结算/特效的窄回调 | 不持有主场景、UI 或模式引用 |
| `combat_runtime.gd` | 同一帧战斗顺序：武器、AI、弹体、接触、死亡和拾取 | 不决定阶段计时/胜利/刷怪计划 |
| `run_flow.gd` | 验证并一次性应用模式结算、等级累积、拾取/Boss奖励 | 不强制下一关相邻、不强制每关商店 |
| `field_layout.gd` | seed 地表、场地中心和相机边界 | 不实现迷宫、墙碰撞或寻路 |
| `modes/*.gd` | 阶段目标、刷怪策略、场地、下一目标/终局/商店/奖励选择 | 不另写战斗或库存系统 |
| `main.gd` | 场景组合、输入和 UI 接线、实体视觉工厂、模态状态、按模式调用共享服务 | 不是第二套战斗/奖励实现 |

上表路径省略共同的 `scripts/`。原 `Rules`、`Effects`、`EnemyAI`、`WeaponRig`、`ActorDirector`、`VFX` 继续复用。主场景保留旧测试访问名称（例如 `g.stats`、`g.build`），但 getter/setter 指向唯一 `CombatState` / `RunSession`，不是复制状态。`spawn_clock` 转发给当前模式；没有隐藏的旧战斗分支。

主场景仍有 UI 生命周期和实体视觉组装；没有声称已完全模块化。后续可按实际房间需求继续分离场景/门/路径服务，而不是现在搭空插件接口。

## 两个用户可玩的模式

- **ARENA SURVIVAL**：原六波、随机环形刷怪、波 3/6 Boss、至少 30 秒且 Boss 必须击杀。原 catalog/balance/encounters JSON 字节保持不变。
- **ROOM ENCOUNTERS · PROTOTYPE**：三次有限遭遇，来自 `data/room_encounters.json`；960×640 可通行场地，预设归一化出生位置，每 0.3 秒尝试计划下一敌人。计划未耗尽时，即使第一帧空场也不能通过；敌人上限导致生成失败不消费计划。召唤子体也必须清除。等待 30 秒不会替玩家清敌。
- 房间清敌后进入 `room_clear`：清掉旧弹体、迫击炮、地带和 proc 临时状态，冻结战斗，逻辑累计 0.6 秒后结算。暂停/背包冻结这 0.6 秒；退出标题/新局取消旧计时。HUD 锁→勾是纯表现，动画完成不触发奖励。
- 前两房每房按模式授予 24 币、15 治疗、一次升级并进入原商店；第三房胜利。场内经验升级仍使用原流程。场地 seed 随阶段确定性变化，角色回到中心。
- 同一次 run 的不同阶段保留构筑；回标题切模式再开始是**新局**，清空旧构筑/临时效果，并递增旧商店/升级 callback 的 generation。没有跨模式永久继承存档。

## 模式 API 的实际边界

`reset` / `begin_stage` 管计划；`regular_request` / `acknowledge` 将“想生成”与“实际生成成功”分开；`boss_request`、`tick_spawn`、`wants_clear_pause`、`advance_clear`、`is_due`、`can_end` 管目标与时间；`field`、`count`、`objective`、`progress` 提供场地/显示数据。

`resolution(session, world, config)` 返回：

```text
{terminal: bool, next_stage: int, shop: bool,
 upgrades: int, coins: finite number, heal: finite number}
```

共享 `RunFlow` 在任何清理或信用变更前验证结果，先标记 transition，再回收地面收益、清理攻击、应用模式指定奖励/下一目标。非法结果不销毁现存实体或改变经济。终局不能同时打开商店/升级。非终局可直接回战斗、只升级、只商店，或升级后商店。`next_stage` 是当前实现的整数目标编号，可以跳跃而非固定加一；不是字符串节点图/门路由系统。

独立 `skip_policy_fixture.gd` 仅覆盖 Arena 的 resolution：阶段 1→3、7 币/3 治疗、无升级/商店；第三阶段直接终局，证明不是由共享层写死 count==6。它是受控测试策略，不是用户菜单中的第三个“完整地牢”。真实运行仍由模式 `is_due` 决定发起结算；保留的直接 `_complete_wave()` 组合层测试入口只核 `can_end`，不替调用者补计时。

## 输入预算

房间配置是独立受校验的数据：场地各轴 48..65536、tile_size 1..65536，**先按浮点 ceil 商检查最多 4096 格，再调用地图分配**；拒绝 NaN/Inf/错误类型。时间范围 0.001..3600 秒，阶段名必须非空字符串，敌人类型来自现有 encounters，位置为 [0,1] 的有限二元数组；奖励币/治疗 0..1,000,000、升级为 1..100 整数。该预算针对本原型，未改变旧 Arena 数据，也不是任意用户 JSON 沙箱。

## 美术与剩余

v9 新 HUD 图尝试了三稿，但均有环境光晕，未达到 clean-cutout 标准。默认运行只用 `ui/mode_status.gd` 的离散像素几何锁/勾，不加载失败 PNG、不用 shader 暗中宣布修好。生产者原稿、prompt、元数据和逐文件 hash 隔离在 `art_source/v9-room-candidates/`；嵌套元数据中的原始 `res://assets/modes/...` 是交接合同，不是游戏启用路径。

v8 现有九帧动作、武器与六主题 VFX 全部保留。本批未新增门碰撞、房间探索/连通、障碍寻路、背包跨局存档、音频或局外成长。GUI/Windows/真人手感和新 HUD 的实际渲染验收仍 NOT_RUN/BLOCKED；headless 模式/生命周期和回归通过不能替代这些验收。
