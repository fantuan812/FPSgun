# v10 Amber Ram普通冲锋敌人：动作生命周期合同

2026-10-22。v9已发布后冻结；本轮只补charger，不扩其余4类、Boss、地牢、音频/职业/存档。依据实读v9 EnemyAI、CombatRuntime、ActorDirector、actor_actions、encounters及ACTION_COVERAGE，并实际查看原charger.png。

## 当前真覆盖与选批理由

charger已有专属九帧walk，idle复用walk首帧。预备/冲锋/恢复、受击、死亡现在均是共享程序化姿态，不是独立九帧。原图是朝左的琥珀橙铠甲机械犀甲虫（象牙钻角、暗炭关节、苔绿脊背），不重做walk。本批只请求3套新九帧：charge_cycle、hurt、death；一张cycle内分段，不虚称每个小阶段各九帧。其他敌人仍共享程序化的缺口继续准确记录。

## 权威玩法（不可被素材改变）

- EnemyAI `move` 接近玩家，cooldown触发时冻结aim和target；warning=.65秒。
- warning耗尽→charging，charge_duration=.6秒，沿锁定aim以310像素/秒移动；结束→recover=.8秒，再move；普通移速36、伤害15、HP42，均维持原配置。
- warning/recover接触安全；move/charging执行原接触判定，半径计算仍16×scale+9（scale1.2，即28.2）。原伤害、玩家无敌计时、刷怪/RNG、掉落/奖励不变。
- 原AI跨步语义不改：tick的阶段分支会return，不把大dt余量补入下个阶段。本轮不借动画重构变更模拟精度。真实_process仍clamp到.05秒；低帧测试要区分该既有行为与直接AI/表现步进测试。
- 受击只暂时覆盖视觉，不能打断/暂停AI、修改aim或免除碰撞。死亡立即退出combat并奖励一次，尸体仅视觉不碰撞，不再出招。

## 建议资产合同（待程序/美术共同锁定后附录覆盖）

`charger_charge_cycle` 9帧顺序0–8：0–3压低身体蓄力；4–6冲锋伸展/角朝前/腿推进；7–8刹停恢复。warning只用预备段，charging只用冲锋段，recover只用恢复段。不是依照整张PNG固定FPS倒推动画事件。hurt9为实际受击反冲→恢复；death9为失能塌落→静止机械残骸，无爆炸白光、无血腥。不得把9张同姿态立绘称连续动作。

三张固定画布、中心横向/固定脚底anchor、统一reference_height，source朝左；复用原体型/配色/轮廓。逐帧不得按bbox重缩放或重居中；alpha bbox用于检边，不用它驱动位移。身体可姿态变形，判定位置不跟头角晃动。朝向、层级、危险线和地面阴影由运行时掌控；PNG不得烘焙预警路径/地面光晕/背景。生成候选如不干净，明确FAIL保留provenance，不默认用失败图冒充生产资产。

## 中断、朝向与时序

1. 视觉优先级death > hurt > authoritative charge phase > move/idle。hurt结束后回到**当前**AI阶段/当前进度，不从0重播蓄力，也不复活已死对象。
2. charger warning/charging朝向应锁aim水平分量（原source面左）；近垂直保持最近朝向。玩家绕背不能让冲锋画面转向玩家，与锁定路径矛盾。死亡保持死亡时朝向。
3. 接触伤害的通用attack trigger不能重启charger蓄力/冲锋时间。专属cycle的phase权威来自AI，接触火花等可独立表现。
4. recover必须读取真实recover_left；可选专属segment metadata避免改变hero/Boss既有release_frame行为。恢复段不是一直冒充walk第一帧。
5. 暂停/背包/升级/商店冻结表现和模拟。rooms清场0.6秒可继续尸体尾播但不恢复战斗；阶段结算/标题/重开必须按合同清理旧对象，无过期回调跨run触发。
6. 降低闪光关闭程序化受击提亮；不能把“减少闪光”称医疗保证或完全无闪光。原图不得包含全屏闪白。

## 独立验收门

- 三图真实帧/region/alpha/anchor/reference一致，缺资源时明确fallback，未通关视觉素材不能默认启用。
- 每一阶段frame只落在允许段；低帧跨段直接显示当前真实阶段，不重播丢掉的释放事件。
- warning和charging中受击，AI计时/位置仍按原规则推进；hurt结束回当前段；hurt→death后不可回attack。
- 同seed同输入、启用/移除新表现两条轨迹：敌pos/hp/ai_state/aim/计时、玩家HP、掉落/金币、RNG状态逐步相同。
- aim锁定后玩家绕背不改视觉冲锋方向；镜像不改实际碰撞。
- 碰撞仍15伤、warning/recover不伤；九帧完成不额外出招、不重复奖励。
- arena/rooms各覆死亡与结算/重开，尸体池上限、无悬空sprite；全旧25入口回归保留，不弱化断言。
- 真GUI/手感若环境仍限制则明确未验，不能以headless代替。最终源码/封包冻结后实算hash并独验ZIP，随后由父任务负责发布。

## 三方冻结附录（16:36 UTC，覆盖建议名称/参数）

程序/美术已锁：ID `charger_charge`、`charger_hurt`、`charger_death`；profile.charger `phase_frames={warning:[0,3],attack:[4,6],recover:[7,8]}`、`phase_driven_attack=true`、`locked_aim_states=[warning,charging,recover]`。通用ActorDirector.observe_enemy(e,previous_ai)仅更新表现；进入recover时从真实recover_left捕获该段时长，写入actor表现状态，不修改AI字段。近垂直锁定朝向不抖；contact trigger不重播phase-driven attack。

结算沿v9保留合法corpse尾播，不能把视觉尸体误判为活敌/碰撞；title/restart/换模式彻底清理。待接入素材质量验收，当前仍是计划，不把未生成资源计作已做。

## 接地修订（16:48 UTC）

源图审查确认death进入帧0/1不是设计腾空，批准仅这两个关键帧显式作者裁片y修正70→59/63，等效补偿脚底11/7源px。PNG、418×320画布、固定anchor、clip统一站立reference/scale、其余7帧不变。不得扩展为全帧自动bbox居中或缩放；倒地塌落形变照旧。有效alpha>8实体不裁切，不带入邻格实体。须重新验27帧/脚底/全回归hash，旧16:45冻结与封包被取代。实际GUI整合验收仍未进行。
