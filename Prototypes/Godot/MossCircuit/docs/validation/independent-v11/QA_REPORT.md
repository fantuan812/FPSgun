# v11 独立验收

状态：17:16 UTC最终冻结源码/资源headless独验PASS；等待程序封包后独立审计。早期fallback记录保留作为过程，不作为最终资源证据。

- 已实读v10 EnemyAI/CombatRuntime/ActorDirector、encounters数值与覆盖表，实看旧spitter九帧图；规格SPITTER_ACTION_CONTRACT.md已与程序/美术确认。
- 17:10–17:11候选：`independent_spitter_parity.gd` 608 PASS。arena/rooms各300步，开启/移除spitter profile比较，实际至少3次shot；逐tick比全部敌弹字段、敌AI/位置/计时/HP、玩家状态、构筑、奖励与三RNG。此阶段素材未加载，仍是profile/fallback验证，须最终真实素材落地后重新跑。
- `independent_spitter_events.gd` 50 PASS。正常warning阈值前无弹、阈值单弹/真实参数，hurt真实HP损失遮挡仍如期发弹，结束当前recover不补发；重复contact拒绝；暂停/lockedaim/近垂直；死亡取消warning并清旧owner弹体/奖励一次、迟到事件不复活；真实rooms清有限roster、重复结算不重复收益/发弹、跨模式旧尸体/弹体清理。
- 第三入口`independent_spitter_assets.gd`已准备，待实际资源验证frame4与真实shot同tick、hurt返回当前frame、27帧固定画布/参考/脚底/顺序；不得把缺资源跳过视为素材通过。

待最终：源图实际查看＋alpha复算、全旧入口与作者/独验fresh import、全部旧runtime.gd字节不变证明、被测版本hash锁、封包ZIP/manifest/分包union审计。实际GUI/真人手感未运行。


## 最终冻结源码与资源独验（17:16 UTC）

- 已逐张实看旧walk及三张新图：同青绿炮壳/紫后罐/奶白炮环/左向身份；shoot4炮管伸展释放、5后坐；hurt后仰回稳；death支腿塌落停留，不是走路代替死亡。无烘焙弹体/火光/危险线。独立PIL只读重算27帧有效alpha>8 bbox均匹配manifest，9帧hash各异（不单凭hash宣称动作语义）。
- 三neutral/death0–2脚底均300，无上批死亡开头浮空问题；整clip固定anchor/scale/reference。非中性帧最大5源px（约1.2世界px）接地微差按美术文档披露。素材为高分辨率像素风/卡通sprite，有平滑细轮廓/渐变，不宣称严格原生低分辨率pixel art。
- Clean snapshot `/tmp/moss-qa-v11-final` 不含.godot，重新import退出0且无ERROR/WARNING。最终**33入口全PASS**（旧29＋作者162项＋独立3入口），独立**857项=parity608＋events50＋assets199**，此时真三图已加载，不再是fallback。
- 资源199项还证明：三九帧实际加载、neutral与旧walk世界身高一致且宽度相差<15%、固定画布/scale/anchor、完整hurt/death帧顺序、warning0–3/recover4–8/attack4唯一帧、越界progress夹取；实际模拟warning末前无弹且frame<4，真实shot同tick弹体+frame4；hurt遮挡不推迟弹体，恢复时frame>4不补播。
- 206个运行/数据/源码/资源/测试输入在原工程、clean import副本及测试后hash一致。`logs/final_runtime_hashes_before.json` SHA256 `4fc56f0efd38dfd64309c95f41db525d5e8ee6e3f8185852d1dc3030fb4232c9`；原3独验脚本hash见`final_independent_script_hashes.json`。
- 独立比较136项旧权威/资产输入字节不变（全部scripts/ui/scenes、旧assets、除actor_actions外的数据、project.godot）。旧动作测试唯一修改为精确9批准ID增至精确12批准ID，其他行未改，不弱化断言。证据`unchanged_authority_assets.json`。
- 最终日志`final_*`、源像素证据`independent_source_alpha.json`；可原字节复制本规格、报告、3独验脚本和这些日志。待封包另写外置PACKAGE_AUDIT，不为了添加审计报告改冻结包。

限制：实际GUI/手感未验；本批仅spitter三个动作clip，不能称所有敌人动画或整款游戏已补完；未新增或重画弹体VFX。v11发布尚待root执行与回读。
