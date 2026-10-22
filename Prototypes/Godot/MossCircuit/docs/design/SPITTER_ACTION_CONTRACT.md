# v11 — Violet Spitter 单敌人动作合同

状态：策划已实读冻结v10代码、动作覆盖表与旧PNG；17:08 UTC已与程序确认最小profile合同；17:16源图/接入/headless独验完成。只写策划/独立测试，不改冻结v10或程序目录。v10已发布commit0260a4fddac838e24ec93b850a3a0a1c2e4fa3bd；本v11尚未发布。

## 真实缺口与边界

spitter为普通ranged敌人，已有专属九帧walk及首帧idle。射击预备/恢复、hurt、death目前是共享程序化，不是三套独立九帧。只补spitter_shoot、spitter_hurt、spitter_death各9帧，不同时扩另外四普通怪/Boss、音效、存档、职业或地牢。沿已有arena/rooms共用CombatRuntime/ActorDirector，不写模式专属表现规则。

权威来源：`scripts/enemy_ai.gd`、`scripts/gameplay/combat_runtime.gd`与`data/encounters.json`。现HP30、speed46、damage8、XP6、scale.95，cd2秒，warning.65秒，弹速145、期望距离230。进入warning锁aim/target；warning到期同一次tick产生shot(count1)，切recover并设recover_left=.7。弹体寿命4秒、真实起点enemy.pos、碰撞半径12照旧。warning/recover接触安全；move接触仍伤8。**本批不改这些值/时序/几何/RNG，也不修原tick跨段不分摊余时的行为。**

## 动作与素材合同

|资源|独立九帧的真实含义|时间/复用|
|---|---|---|
|spitter_shoot|0中性，1–3壳体蓄压/稳定炮口，4真实发射时炮管伸展，5后坐、6–8回稳|0–3由真实.65s warning进度；4–8由真实.7s recover进度；并非每子段另有9帧|
|spitter_hurt|0中性→短后撤/罐体晃动→回稳|原hurt .27s；不改AI受击硬直，现没有新增硬直|
|spitter_death|0中性且接地→支腿塌落→炮壳倒伏|原death .72s，立刻离开combat、仅视觉尾播|
|既有walk/idle|原九帧walk/原首帧idle|不重画，不把其算新增|

美术保持左向三分之四：青绿前甲、紫色后罐/圆炮嘴、奶白炮口环、黑灰软管、黄铜/橙金机械四足关节与少量苔斑。源参考`assets/enemies/spitter.png`已实看。不能生成有机怪替代机器身份。身体图不烘焙弹体、喷火、危险线或大面积光晕；已有弹体/VFX仍独立，释放姿势不是第二次发弹。

透明PNG逐图固定画布/裁片尺寸，建议沿418×320、anchor[.5,.9375]但最终须实测；三图各用中性站立帧reference_height，全部映射旧walk可见实体参考高度（不是透明画布高度）。整clip统一scale与脚底，不逐帧bbox缩放/自动居中。死亡帧0/1不能无意浮起；若源生成漂移，允许显式作者指定两三关键帧裁片偏移，逐点验证有效alpha>8实体保留、不引入邻格，并记录原因。不能把裁片修正用于抵消真实倒下压扁。

## 最小表现仲裁（三方执行合同）

沿现有profile：attack=spitter_shoot,hurt=spitter_hurt,death=spitter_death；phase_frames warning[0,3],recover[4,8],attack[4,4]；phase_driven_attack=true；locked_aim_states[warning,recover]。复用observe_enemy在EnemyAI.tick之后的观察：实际warning→recover同tick会发shot且recover进度0显示4；不通过动画回调触发弹体。若实现需要显式事件观察，必须仍只读既有event，不另造定时器或消费RNG。

- warning不能显示释放帧。正常shot发生时（无hurt遮挡）显示4，帧4–8随recover前进，不因contact/重复trigger从4重播。
- hurt优先于射击身体，但不阻止真实shot或计时；hurt消失显示当前阶段/进度，若已进恢复5–8不能补播4。不承诺受击遮挡期间仍可见身体释放帧；独立弹体是实际发射证据。
- death高于全部；扣至0前死亡取消后续warning，死亡当tick已有弹体按原owner清理，奖励一次。表现不得让尸体继续发弹、接触或复活。
- warning/recover视觉朝向锁aim水平分量；abs(x)<=.001保留最近朝向，玩家绕背不翻炮口。死亡保持最后朝向。move按原朝向逻辑。
- 暂停/背包不推进AI/动作。rooms清场与arena结算沿v10约定：可保留合法视觉尸体尾播但无活敌/弹体，title/retry/切模式新run完全清旧对象，generation隔离。

## 独立验收计划

1. 读实际diff，EnemyAI/战斗伤害/弹体/经济/RNG原字节或逐规则确认不改；不能为动画另加射击等待。
2. 同seed同输入、同模式的专属与移除profile fallback两实例逐tick比较敌AI/位置/HP/aim/timer、所有敌弹pos/vel/life/owner/damage、玩家HP/构筑/奖励/三个RNG；arena/rooms各覆盖至少两次真实shot、受击遮挡和死亡。外部大dt沿生产clamp，不误称任意大dt物理等价。
3. 正常warning末前无弹/帧<4；越阈值同tick单弹+4；恢复不重复发射；低FPS跳跃不重放；warning期间hurt跨shot，实际弹不延后、hurt恢复不补发；contact attack被拒且不能假射击。
4. warning死亡无迟到shot；shot后死亡owner弹体清除/奖励一次；暂停冻结、恢复继续；rooms清场/标题/跨模式重复调用不能留炮弹/尸体/回调或多奖励。
5. 全27帧实际资源/透明有效bbox/固定画布/脚底接地/与walk相对头身尺度；三neutral参考世界身高一致，窄小姿势不逐帧归一。源图实看与像素检查不是GUI窗口验收。
6. 全旧入口及新增作者/独立测试，clean import，实际被测源/资源/脚本hash锁定，封包manifest/全部ZIP CRC/SHA/互斥分包union逐byte核对。旧v10冻结不可被覆盖。

程序17:08最终确认采用既有phase_driven_attack/phase_frames方案，不新增release_index或事件框架；本批不另加能量VFX，保留既有独立弹体。

实际交付：三图1254²、每帧418×320，anchor[.5,.9375]；站立reference_height为shoot213/hurt222/death252。原图实测shoot4为炮管伸展、5后坐，已按实际姿势描述；不改变释放帧4合同。原图为高分辨率像素风/卡通sprite而非严格原生低分辨率pixel art，nearest不等于原生像素化。GUI仍未验。
