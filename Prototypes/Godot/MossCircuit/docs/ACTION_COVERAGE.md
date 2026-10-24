> **v13 当前覆盖**：五种普通敌人已有独立 hurt/death；crawler/flanker 本次新增 hurt9/death16，近身虚假 warning 已删除，但真实接触攻击仍为程序化脉冲。Boss 独立 hurt/death 尚缺。下面 v7–v12 各段为历史记录，不代表当前全部缺口。见 [接触敌人合同](CONTACT_ENEMY_ACTIONS.md)。

> **v8 修正**：本文保留 v7 动作批次的覆盖记录。运行时主角攻击已改为 `assets/weapon_mounts/clean_hero_attack.png` 空手动作，不再使用旧枪火烘焙图；只有主手非环绕锯触发身体攻击，辅助位仅播放独立武器反馈。新装配、挂点与几何边界见 [MODULAR_WEAPONS.md](MODULAR_WEAPONS.md)。

# v7 动作、事件与缺口覆盖矩阵

本批是有限的动作表现升级，不是“所有游戏特性已经齐全”。新增六张独立九帧原图（54 帧），保留既有玩法伤害/冷却/AI/RNG。`scripts/actor_director.gd` 统一仲裁，数据在 `data/actor_actions.json`，原图与裁片合同见 `art/actions/README.md`。

## 角色动作：逐对象实际实现

|对象|待机/移动|攻击预备→释放→恢复|受击|死亡|冲刺|
|---|---|---|---|---|---|
|玩家|旧九帧 walk / 其中首帧 idle|新 `hero_attack` 九帧源；按实际事件分段播放|新 `hero_hurt` 九帧|新 `hero_death` 九帧，末帧保持后结算|新 `hero_dash` 九帧，按实际 dash_time|
|crawler 追踪甲虫|旧 beetle 九帧 / 首帧|共享程序化靠近警觉、接触攻击脉冲、恢复；没有新增可躲前摇|共享程序化后退/变亮|共享程序化倾倒/缩扁/淡出|无该动作|
|charger 冲锋怪|既有专属九帧 / 首帧|真实 AI warning 蓄力；charging 释放/持续；recover 恢复；共享程序化姿态|共享程序化|共享程序化|既有冲锋，不是玩家冲刺|
|spitter 远程怪|既有专属九帧 / 首帧|实际 warning→发弹→recover；共享程序化姿态|共享程序化|共享程序化|无|
|flanker 侧袭怪|既有专属九帧 / 首帧|共享程序化近身警觉/接触攻击；并非新承诺前摇|共享程序化|共享程序化|无|
|brood_keeper 召唤怪|既有专属九帧 / 首帧|实际召唤 warning→spawn→recover；共享程序化姿态|共享程序化|共享程序化|无|
|boss_warden 守门者|既有专属九帧 / 首帧|新 `boss_warden_attack` 九帧；复用于已有冲锋/爆发招式，非每招独立原画|共享程序化|共享程序化|原冲锋|
|boss_core 核心|既有专属九帧 / 首帧|新 `boss_core_attack` 九帧；复用于实际释放招式，非每招独立原画|共享程序化|共享程序化|无|

“共享程序化”是以 idle 姿态做随时间变化的缩放、偏转、反冲或淡出，不是九帧独立原画，也不拿行走循环冒充攻击。五普通敌人及 Boss 的专属受击/死亡原画仍待后续制作。玩家射击原画是通用射击身体动作，不宣称六种武器已有六套握持动画。

## 原有战斗时序不被素材控制

- Manifest 的 `release_frame`：玩家 **3**、守门者 **5**、核心 **4**。源帧均保持 0→8 原始时间顺序，不倒排恢复姿态凑统一帧号。
- 玩家武器即时发射不变：真正发射从对应释放帧开始，烘焙枪火不会延后到一个虚假的第二次射击。只有冷却剩余小于 0.12 秒且有活目标在该武器射程内，才展示预备帧。**初次开火/快速连射不保证看全九帧**，不为播放完整原图暗加伤害前摇。
- Boss/有技能普通敌人读取既有 AI `warning/charging/recover`。警告阶段只显示释放帧之前；真正释放才进入释放段。冲锋按剩余真实持续时间推进，不因反复 trigger 重播倒帧。
- 优先级：death > hurt > dash > attack > 移动/待机/预备。多武器同一时刻或 0.08 秒内的重复攻击合并表现，较后的实际射击可重启释放帧；所有实际攻击仍有既有枪口/弹道反馈，伤害不被表现优先级取消。
- 受击动画根据实际扣血触发；护盾抵挡走护盾反馈，不伪装成已经扣血。敌尸体立即脱离 combat 数组、奖励立即仅一次；纯视觉尸体最多 40 个，0.72 秒后回收。
- 玩家死亡立即结束玩法，九帧尾播后再保持末帧约一帧时长才显示结算；不能因此继续攻击/奖励。重开和标题清掉旧尾播，不依赖延迟回调。
- 暂停、背包、升级、商店、显示设置冻结动作时钟。死亡/胜利只推进死亡尾播；标题/重开清理旧实例。

## 尺寸、枢轴与降低闪光

旧 walk 的可见尺寸并不等于 PNG 画布尺寸。注册时从旧 AtlasTexture.region、margin、scale、offset 计算实际可见身高与脚底 baseline；新动作使用固定 reference_height 及固定 anchor 对齐该 baseline，避免站立切攻击突然长大。帧间不做独立 bbox 重缩放或重居中。生成素材仍有少量自然漂移，不宣称手工像素级完美对位。

DISPLAY SETTINGS 的 Reduce flashes 会立即取消受击额外白色提亮，并把独立 VFX 图层透明度降至 40%；暂停中切换不推进计时。设置仅本次运行会话有效。原图中烘焙的枪火仍是原图一部分，几何危险轮廓保持可读；这不是完全无闪烁模式或医疗安全保证。

## 道具机制表现与来源

以下全部复用已有六种九帧 VFX，通过来源元数据、位置、色相、尺寸及既有判定几何区分，不虚报新增十四套独立动画。`_mechanism_vfx` 为装饰事件按 source_item 节流 0.08 秒，**不修改道具逻辑 ICD**。链电每条真实连线、护盾抵挡和地雷爆炸由各自既有事件节制，保留多目标完整反馈。12 件数值型旧道具仍是被动效果，UI 显示属性，不伪造主动触发动画。

|道具/联动|实际触发与可见反馈|来源/验证|
|---|---|---|
|arc_relay 链电|真实主命中后连向不同目标；端点精确的 chain_arc + 命中火花|`source_item=arc_relay`；effects/vfx 独验|
|kill_cell 能量拾取 / 与链电配对|真实主击杀生成金色能量拾取，生成点金色火花；充能在 HUD|kill_cell；effects / independent_v4|
|dash_resin 冲刺地带 / pulse_boots 配对|冲刺落地带的黄色火花、持续区域/减速边界；配对仅减速普通移动|dash_resin；效果逻辑原样|
|mirror_shell 护盾 / thorn_crown 配对|真实抵挡才播 shield_impact；反击有范围反馈，HUD 护盾消耗|mirror_shell；effects / independent_v4|
|thorn_crown 荆棘|真实受伤反击时珊瑚色 shield_impact/范围圈|thorn_crown；原 ICD 不变|
|blood_valve / blood_mines|真实低血回血或地雷配对击杀回血时绿色短 shield_impact|blood_valve / blood_mines；血量边界旧测试|
|scrap_mine|正常拾取落雷时金色火花；真实爆炸才播 explosion，范围边界保留|scrap_mine；地雷数量/递归排除旧测试|
|pulse_boots|真实冲刺推开时薄荷色 dash_trail 与推开圈|pulse_boots；真实推动不由动画反驱动|
|return_spool|返航刃有效命中且实际回复时绿色反馈|return_spool；双腿去重/ICD旧测试|
|blast_fuse|迫击炮真正爆炸后余烬地带，橙色火花+持续边界|blast_fuse；延迟爆炸/余烬旧测试|
|echo_chamber|第 5 次符合条件主命中产生紫色目标火花/回声圈|echo_chamber；proc 排除旧测试|
|gravity_anchor|地雷拉拽的紫色 shield_impact/吸引圈|gravity_anchor；原拉拽距离不变|
|medic_seed|累计真实承伤产生医疗拾取时粉色火花；拾取有绿色生命符号|medic_seed；护盾不计承伤旧测试|
|phase_capacitor|冲刺储能下一次主命中的青色爆炸|phase_capacitor；单充能/递归排除旧测试|

无资源或池满只降低表现，不阻止实际伤害；不消耗 gameplay RNG。装饰节流缓存在重开/波次/结算清理，模态页面冻结游戏 elapsed，因此不会偷偷刷新冷却。

## 验证入口及剩余

- `tests/test_actor_actions.gd`：真实六资源、九帧时间/优先级、死亡位置/尾播/回收、即刻奖励、设置、表现节流/RNG、title→restart。
- `tests/independent_actions.gd`：独立动作与状态、真实 metadata 释放帧、参考身高/脚底一致、暂停与重开。
- `docs/art/actions/`：54 帧真实 alpha、窗口边界、源顺序检查与生成记录。
- `ui/test_ui.gd`：设置意图、HUD 状态/冷却快照与焦点；所有既有玩法/经济/构筑/敌人/VFX 回归仍执行。
- 两个旧独验原来把 `hero.speed_scale==0` 当暂停条件，已改为手动动画的 frame/age/walk_time 不变且未引擎自动播放；保留 elapsed 不变断言。这是实现变化后的语义检查，不是删除暂停测试。

未完成：普通敌人和 Boss 每种独立 hurt/death 原画、各武器独立握持/装填、音效音乐、存档/局外成长、随机障碍连通地图、真人平衡与 Windows 导出。GUI 仍受环境权限限制，没有实玩或真实窗口截图，headless 通过不能替代这些验收。


## v10 局部补齐（不改历史记录）

冲锋者已新增 charger_charge（0–3蓄力/4–6冲锋/7–8恢复）、charger_hurt、charger_death，各9帧；walk/idle沿用旧图。采用profile段映射、锁定aim镜像和实时phase恢复，不改变EnemyAI。其他普通敌人仍使用原来的共享程序化反馈，不能把本节解释成五类都已完成。详见 [本版合同](CHARGER_ACTIONS.md) 和 [原图限制](art/charger/README.md)。

## v11：普通远程 Spitter

本批仅射击0–3预警/4释放/5–8恢复、受击与死亡三套原画；三张源图已通过目视/结构门槛并接入，33入口最终clean全回归已通过（非GUI渲染验收）。运行脚本不改，复用v10数据驱动映射；其他三种普通敌人仍非全独立原画。详见 [本批合同](SPITTER_ACTIONS.md)。

## v12：Moss Broodkeeper

召唤16帧（0–6预警/7尝试/7–15恢复）、短受击9帧、死亡16帧已接入，修订后37入口全过（非GUI验收）。索引7不保证生成子体，cap/父死子存/Rooms清场仍由原战斗与模式决定；仅表现加载器泛化真实N，权威脚本不改。九帧为生图便利而非动作上限，旧9/9/9候选及其测试只属历史。详见 [本批合同](BROODKEEPER_ACTIONS.md)。
