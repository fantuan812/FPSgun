# v12 Moss Broodkeeper 召唤者动作

## 选择与权威边界

基线FPSgun已发布v11 `04ab91d2ec3c7777d8276def66bddb766b28654a`。剩余普通敌人中，召唤者有真实warning→summon→recover事件，适合复用既有数据接口。Crawler/Flanker没有真实攻击前摇，不能套用召唤/射击原画虚构可躲安全窗；本批不补它们的独立动作。

权威战斗/AI/模式/经济脚本、旧资源、敌人/房间/构筑配置保持原字节。仅 ActorDirector 的表现加载与索引上界由固定9改为真实剪辑长度，追加 `actor_actions.json` profile与manifest入口，ID为 `brood_keeper_summon`、`brood_keeper_hurt`、`brood_keeper_death`。

| 阶段 | 身体帧 | 权威 |
|---|---|---|
| 移动/站立 | 旧walk/首帧复用 | 近距离后退，旧AI不变 |
| 预警 | summon 0–6 | 原 .65秒，不新增子体 |
| 尝试释放 | summon 7 | 原summon事件同tick进入recover0；只是尝试，不保证产出 |
| 恢复 | summon 7–15 | 原 .7秒，不追加动画计时/伤害/召唤 |
| 受击 | hurt九帧 | 共享 .27秒优先显示，AI继续；结束回当前状态，无补召 |
| 死亡 | death十六帧 | 共享 .72秒纯表现尾播，父体立即退出战斗、奖励一次 |

`phase_frames` warning[0,6]/attack[7,7]/recover[7,15]，`phase_driven_attack=true`拒接触反馈重播召唤；warning/recover锁定原aim朝向，近垂直保留上次方向。

## 帧数不等于生成批次

用户确认九帧不是动作上限。原9/9/9候选已外置保留、未发布，其作者163项结果不转移到本修订。最终合同为 **16/9/16**：两张4×4长动作、原短hurt九帧，必须真实不同姿态，不能复制帧凑数。warning7姿态沿原.65秒推进，recover9姿态沿原.7秒推进；death16沿原.72秒、hurt9沿原.27秒。

单图clip支持 **2–256** 个合法帧记录；sheet列数不是时间轴长度。所有帧的逻辑画布必须同尺寸（每轴≤4096），源裁片必须整数坐标、非空且在源图内，非法clip不加载而用既有程序化fallback。`valid_segment(value,frame_count=9)`保留旧九帧默认；实际播放按该clip真实N校验段上界。旧9帧metadata/资源/映射不变。本批单张4×4避免跨图尺度跳变，**尚不支持同clip跨多PNG**，带frame.path的记录明确拒绝，不静默使用错图。

低FPS可跳过中间姿态，不排队补播召唤、不延迟AI恢复/死亡退出，也不为了看完16张延长权威时间。正常.05秒步进death的末帧15在age.70出现，age超过.72释放尸体；headless索引测试不是显示帧率保证。

## 不是出怪保底

原规则每次尝试最多1只Crawler，最多3只活子体，同时受全局90敌人上限限制。满上限时仍可做原有召唤尝试但新增0只，**不可根据索引7的释放姿态强制补1只**。死子体不计活上限；子体位置/ID/parent_id和实际生成时序完全来自原战斗层。

父体死亡不会自动清理已活子体。Rooms要清完计划和所有活敌，因此仍活的子体继续阻塞清场；不能为播放死亡图直接删除子体或提前结算。重开/标题/换模式则清理整个旧战场与表现引用。

## 图像与分层

仅身体/背部蜂巢机械动作，不把子体、卵弹、外部光效烘焙进图中，避免满cap时出现“画上有小怪、实际没有”的假反馈。已有子体仍独立sprite，玩家武器/VFX系统不变。

支持可选 `frame.margin=[left,top,total_extra_width,total_extra_height]`（Godot AtlasTexture语义），把不同整行的安全裁片透明补齐到固定clip逻辑画布；未提供时全0。margin非负整数且left/top不超过总补量；alpha_bbox用padding后的逻辑坐标，原图像素不改，不把相邻行装进帧。每整行共用补量，不逐帧bbox重居中。语义参考 [Godot AtlasTexture 官方说明](https://docs.godotengine.org/en/stable/classes/class_atlastexture.html#class-atlastexture-property-margin)，实际画布尺寸另由Godot headless资源测试验证。

固定clip逻辑画布、脚底anchor与中性首帧reference_height，按旧walk可见站高缩放，不逐帧bbox归一。源图是高分辨率像素风sprite，并非严格原生低分辨率逐像素动画；nearest不能消除该风格边界。实际素材接地/透明边界需要通过目视和结构检查后再计入运行集。

死亡源网格3→4曾出现14源像素非有意回站，已由美术与策划实际姿态审查后重排为 `[0,1,4,5,2,3,6,7,8,9,10,11,12,13,14,15]`。每个真实姿态各一次，记录`source_index`可追溯；PNG/裁片/padding/anchor/reference不变，相邻高度最多+1源像素。不是自动按bbox排序或缩放掩盖问题，旧证据保存在艺术history中。召唤恢复仍有较明显的生成节拍，未声称手工精修流畅度。

## 验证

作者 `tests/test_brood_actions.gd` 覆盖实际召唤、两种cap、同tick真实受击、父死子存、暂停/重开。策划独验已比两模式同输入下所有子体/AI/构筑/三RNG及生命周期。修订后clean import与37入口全通过：原33入口、作者229项、独立610+66+374=1050项；221运行输入hash一致，另核3独立脚本，见 [独立报告](validation/independent-v12/QA_REPORT.md)。原旧9帧/重排前证据不转移。

GUI/Windows实玩仍未运行；原画结构与headless状态测试不是渲染/手感验收。其余两种普通敌人、Boss部分独立动作、音频/存档/完整地牢仍未补齐。
