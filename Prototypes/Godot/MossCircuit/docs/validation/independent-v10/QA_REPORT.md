# v10独立策划/动作验收记录

状态：接地修订后最终源码/资源全量独验PASS（16:51 UTC），待新封包审计。旧16:45冻结不再作为发布版本证据。仅headless，非GUI/真人实玩。

## 早期逻辑验证（历史）

- `independent_charger_gameplay_parity.gd`：366项PASS。arena/rooms两个相同seed实例，一个新charger profile、另一个删除profile/新资源回旧程序化表现；180步/模式，含.2/.8外部帧delta（生产_process仍按原逻辑clamp .05），穿插受击/死亡。每步比较敌位置/HP/aim/AI状态/计时、玩家HP/位置、经验/金币/击杀、三个RNG状态相同。
- `independent_charger_lifecycle.gd`：30项PASS。锁定aim/近垂直不抖、hurt覆盖结束回当前phase、五次contact不能重播、recover span一次捕获、低帧受击结束回已变更move、暂停冻结；真实战斗warning/recover接触安全、charging15伤；死亡立即退出combat/奖励一次、迟到反应不复活、不翻尸体；跨模式重开清尸体。
- 新资源尚未落地，所以以上是运行逻辑与fallback阶段的中间验证，不计作3张新九帧视觉/几何通过。

## 当时列出的验收门（已由后续实测关闭，GUI除外）

三资源真实内容与帧窗口/固定锚点/reference/镜像；帧映射预备0..3、冲锋4..6、恢复7..8；受击/死亡真实9帧及越界安全；同参考体型/alpha可读性，不把生成背景晕当生产合格。然后全旧25入口+新作者/独验，最终hash和ZIP封包一致性。

## 源图独立查看与像素检查（16:43 UTC）

已实际查看旧walk及三张新sheet，角色钻角/橙甲/苔背一致，charge蹲低→伸展→恢复、hurt反冲→回正、death塌落保持可辨；未见v9候选信标那种宽环境晕。仅读像素重算27帧alpha>8 bbox全部匹配manifest；三中性站立帧宽高比1.519/1.529/1.518一致，各clip用站立参考183/174/199统一到同world高度，不逐帧重缩。

已知限制：固定脚底anchor下death首帧脚底比anchor高11源px（约3.8世界px），美术确认是源生成行内接地不齐，不是设计腾空；其余charge最多2源px、hurt最多3源px。保留整个clip固定锚点和真实姿态变形，不盲目逐帧归一或整体下移导致末帧下沉。需实际GUI微调，不称完全接地或整合画面通过。读像素明细 `logs/independent_source_alpha.json`。


## 修订前冻结验收（16:45 UTC，已被下节取代）

- 从冻结v10复制到/tmp/moss-qa-v10-final，不携带.godot，真正clean import退出0，无ERROR/WARNING。
- 29入口全部PASS：旧25、作者test_charger_actions（128项）、独立3脚本（366+30+191=587项）。每个日志同时查退出码、ERROR/SCRIPT ERROR及通过摘要，见logs/final_regression_summary.json和final_*.log。
- 新资源独验191项：3图实际加载为专属九帧、固定画布/窗口/alpha声明界内；中性站立帧按旧walk可见实体等高且身体宽度相差<15%；整clip固定scale与脚底anchor、不引擎自动播放；charge段仅0..3/4..6/7..8，越界progress夹取不越段，低帧跳过阶段直接显示当前恢复而不重播。
- 191个程序/数据/运行资源/测试输入，原工程与clean import测试副本前后hash全部一致。冻结清单SHA256：03ce8e82a878e293fa0cf381dfbfc9c00afa97d99cf6ad8f9082608a8071e469。清单在logs/final_runtime_hashes_before.json，核验在final_hash_verification.json；自有3脚本hash在independent_script_hashes.json。
- 实读diff：EnemyAI字节未改；CombatRuntime仅把原视觉phase/mirror块改为ActorDirector.observe_enemy。旧test_actor_actions唯一语义修改为原assets.size()==6更新成精确9批准ID集合（原6+新3），未删除既有断言或放宽期待；增加3素材后循环断言从114到147项。
- 美术实看与headless几何证明不是实际窗口整合验收。death首帧约3.8px接地漂移限制保留，不称全部敌人动画补齐（本批仅charger三clip）。

程序可原字节复制本目录3个.gd与最终报告/证据；待整包生成另写PACKAGE_AUDIT，不为审计报告反复改已冻结包。


## 接地修订后的最终冻结验收（16:51 UTC）

- 已按作者指定仅将death帧0/1 region.y从70改59/63；固定418×320、anchor、reference199与三PNG原字节不变，其余25帧不改。独立逐点对比27帧alpha>8源坐标集合完全相同，没有实体裁切/邻帧污染；两指定帧有效脚底均为300，已消除确认的11/7源px浮起。alpha1–8微碎点变化由美术说明，不能误称所有RGBA切片字节不变。
- 干净副本 `/tmp/moss-qa-v10-grounded` 重新import，退出0且无ERROR/WARNING。29入口再次全部PASS（旧25＋作者130项＋独立366/30/194=590项），不是迁移旧结论。新增独立3断言专门固定两帧裁片位置和脚底。
- 191个被测运行/源码/数据/资源输入在原工程、导入副本及测试后完全一致；`logs/grounded_runtime_hashes_before.json` SHA256 `d7ebfc5aa32e6051c6f726377a89269425ef20b4b796d3fe11bc79e8e9713bab`。3独立脚本当前hash在`grounded_independent_script_hashes.json`。
- 最终证据为`grounded_*`日志、`grounding_fix_pixel_verification.json`与本节。先前`final_*`仅保留历史；旧整包已被程序隔离，必须重新封包核验。
- 这关闭的是已知源裁片接地问题，不等同实际GUI运行/整合手感验收。只补普通charger三条九帧clip；其余敌人仍有程序化动作，未声称全游戏动作补齐。
