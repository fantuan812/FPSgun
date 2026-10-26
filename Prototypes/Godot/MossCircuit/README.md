# v30 development candidate — explicit weapon order (UNVERIFIED)

Shop-only **MOVE EARLIER / MOVE LATER** lets an owned weapon copy trade places with its neighbor without selling it. Its exact remaining cooldown travels with it; no clock reset, scrap, stat or RNG change. This changes existing ready-weapon processing order and existing mount assignment, not projectile travel rules or guaranteed damage. Duplicate copies remain separate slots. Outstanding shots/mortars block the action rather than being discarded.

This candidate is **not yet accepted**. True cold import, 321 focused author checks and retained reservation520/salvage147/weapon-rig245 checks pass. Independent candidate/native/final-pack acceptance is still pending. Implementation is scoped to the [frozen contract](docs/V30_WEAPON_ORDER_CONTRACT.md). Old no-action parity, strict stale/type guards, copy-clock/rig preservation, finite actual Cryo/Saw timing, native controls and exact-pack acceptance remain pending. No new art/catalog content or chat attachment is planned. Accepted v29 below is immutable.

---

# MossCircuit v29 — trade one stat choice for 10 scrap

Each earned upgrade page still offers three of the same six permanent stats. A separate optional **SALVAGE THIS UPGRADE / +10 SCRAP** resolution forfeits that one stat choice, retaining earned level/XP. This trades lasting growth for equipment budget at a later normal shop, if reached; no extra shop, reroll, choice, discount or automatic purchase is created. Ten is experimental tuning, not a general balance guarantee.

The payout is one guarded integer credit, unaffected by coin bonuses and preserving fractional credit exactly. Existing selection order and ordinary automation remain unchanged. Catalog, art, encounters and the reserved-offer policy are untouched. The complete 40-case no-salvage old-state/RNG projection equals v28.

- Author and independent final engine gates: 90 standalone entries + import, with all 601 frozen inputs unchanged; initial cold import and final reused-cache revalidation are distinguished. Independent runner-only success-marker false negatives were explicitly reconciled against retained successful logs, not hidden or treated as product failures.
- Independent runtime 294 and UI 901 checks pass in source and the exact exported PCK; independent resource verification 837 and Python safety 3 pass. Controlled actual 960/1280 keyboard/mouse review covers both modes, default SELECT, optional salvage, scrolling, mixed queues and held-Rail affordability/purchase. No controller binding was added.
- One ordinary exact-Linux seed-128 Rooms route earned the first encounter's choices: 66 scrap → salvage via Tab/Space → next queued choice 76 → normal Repair Plating SELECT → normal first shop 76. Rivet remained at 15 primary damage/0% global damage bonus; the subsequent Repair selection accounts for 120 HP/max HP. Automated CUA/tactical pauses, no injected state, no purchase or full-campaign claim.

Restore the [complete PCK and manual backup instructions](../../../Deliveries/MossCircuit/v29/READ_ME_v29.txt) using the unchanged verified executable. Windows is existing executable + new resource pack, not Windows runtime acceptance. Native ALSA/dummy-audio and unsupported-VSync limits remain explicit; terminal Ctrl+C closure is not in-game graceful quit. GitHub-only delivery, no chat attachments.

See the [frozen contract](docs/V29_UPGRADE_SALVAGE_CONTRACT.md), [implementation and finite findings](docs/V29_UPGRADE_SALVAGE.md), and [independent evidence](docs/validation/independent-v29/QA_REPORT.md). Final reachable commit identities are recorded separately in the delivery version index; local acceptance alone is not a publication claim.

---

# MossCircuit v28 — reserve one shop offer

A build-planning decision, not another stat item: **RESERVE one unsold offer for free**, even when unaffordable or equipment slots are full. Its original price and draw metadata survive refreshes and later shops. The trade-off is one occupied stock slot: the unchanged 5-scrap refresh draws only three fresh offers. It is not owned equipment and grants no stats, tags or synergy. Explicit RELEASE leaves current stock untouched; successful purchase consumes the hold; terminal results and new runs clear it.

- All 37 catalog entries, six upgrades, economy amounts, art and combat remain unchanged. Without a reservation, 80 controlled shop/transaction cases, 800 seeded draws and 3,200 combat steps match v27 exactly. Using a hold intentionally changes the fresh-draw path.
- Final author and independent suites: 87 standalone entries + import, with unchanged tested inputs. Independent reservation checks 901, malformed-record/data checks 285, UI layout/callback/action checks 3,170; exact pack 837 and packed reservation 901 pass.
- Actual native keyboard/mouse review covers both modes at 960×540 and 1280×720. Default ui_accept has keyboard bindings only; synthetic action dispatch is not physical-controller support. No binding was added.
- One ordinary seed-128 Rooms attempt reserved Rail, bought Power, refreshed into unaffordability (38 scrap), carried Rail into the next natural shop (73), then purchased it for 42 (31 remaining), with SOLD/clear and equipped SLOT2 observed. Automated CUA/tactical pauses; no state injection or full-campaign/balance claim.

[GitHub runtime restoration and manual backup/replacement](../../../Deliveries/MossCircuit/v28/READ_ME_v28.txt) uses a complete new PCK with the unchanged verified executable. Windows remains existing executable + resource pack, not runtime-tested; cloud audio/VSync limitations remain explicit. No chat attachments.

See the [exact contract](docs/V28_RESERVED_OFFER_CONTRACT.md), [implementation and validation notes](docs/V28_RESERVED_OFFER.md), and [independent evidence](docs/validation/independent-v28/QA_REPORT.md). Earlier version documentation below is retained history, not an assertion that every old acceptance scope was repeated.

---

# MOSS CIRCUIT · v27 · Broodkeeper 空心脉冲

现有 Moss Broodkeeper 现在先预警 1 秒，在固定中心的 **70–180 像素闭环带**尝试一次原有 **11 点伤害**，再与旧召唤交替。两条橙边均危险；可以向内进入空洞，或向外离开环带，但其他攻击仍会命中。没有新敌人/道具/场地或随机抽取；召唤机会改为隔次，明确属于遭遇内容变化。复用原有 16 帧撑起/收势素材，不称为新绘制动画。

已通过独立 83 个入口 + 导入再验证、948 项共享机制检查、45 项数据检查、835 项精确 PCK 检查及两模式 960/1280 受控原生审查。未改动的敌人/旧构筑 3,200 步轨迹与完整商店池 800 次抽取保持等价；不要求故意改变后的 Broodkeeper 轨迹等价。完整冻结语义见 [合同](docs/V27_BROOD_PULSE_CONTRACT.md)，有限验证/发现记录见 [本批说明](docs/V27_BROOD_PULSE.md)。

普通操作以种子 2701 完成一次 Rooms 流程：观察第 3 房第一次空心预警，之后环外玩家 140/140 HP，直接观察终局 Room 3/3、LV 4、11 kills、Rivet/0 模块。未清晰捕获第二次召唤或普通操作的 11 点伤害归因；精确机制来自受控与包内测试，不能从截图推断。云端 ALSA/VSync 限制仍在；Windows/声音/长期平衡未验收。

GitHub-only 交付源码/证据与完整 PCK 分块，不发送附件、不重复 EXE/ELF。恢复脚本 `--version v27` 生成一个完整 PCK 与手动备份/替换说明；需要已有校验一致的程序，首次安装先恢复完整 v19 平台包。旧版本保持不变，实际发布身份与可达性另由版本索引及远端读回证明。

## v26 Feedback Diode（历史）

新增唯一模块 **Feedback Diode（28 废料）**：装备后成功开始冲刺，在原有冲刺窗口里真正接触敌方子弹，可对仍存活的原射手造成一次固定 **24 点次级伤害**。每次冲刺最多一次，擦身、近战和爆炸不触发；不延长无敌，不产生主命中连锁。与 Pulse Boots 的 CROSSCURRENT 组合提供近敌推开 + 远程反击的互补玩法，没有隐藏倍率。一个原创图标与轻量紫色回线；旧装备、碰撞、模式政策和无此模块时的行为保持不变。新增商店项会改变跨版本种子货物，不宣称旧版本完整商店池相同。

已通过独立冷导入 + 80 个独立入口、380 项新机制/交易/类型检查、833 项精确 PCK 检查及两模式 960/1280 受控原生界面审查。有限普通操作用种子 433 实际赚取并购买 Diode + Pulse，观察 ACTIVE 组合并尝试冲刺接触射手子弹；**未捕获短暂回线，不把该次普通操作称为成功反击/24 点归因证明**。精确伤害与归因来自受控和包内测试，不是截图推断。

交付改为 GitHub-only：源码在本目录，完整新 PCK 通过 [交付目录](../../../Deliveries/MossCircuit) 的既有校验恢复工具还原，然后按说明备份旧 PCK、手动替换。程序本身不变，不重复保存 EXE/ELF。Windows 未实机运行；云端 ALSA、VSync 及一条 XServer BadValue 启动诊断保留，不声称音频、零错误启动、完整通关或广泛平衡验收。显示设置仅当前会话有效。

详见 [冻结语义](docs/V26_FEEDBACK_CONTRACT.md)、[实现与失败修正边界](docs/V26_FEEDBACK_DIODE.md)、[独立证据](docs/validation/independent-v26/QA_REPORT.md) 和 [交付说明](docs/DELIVERY.md)。

---

# MOSS CIRCUIT · 苔芯幸存者 v25 · 标签协同进度（历史）

本批只补齐三个既有标签协同的可发现性：背包显示当前装备副本数 / 门槛、启用状态、既有目录效果及准确适用范围。重复武器和实际模块副本计数；达到门槛只生效一次。电/近战是匹配武器的加算伤害加成，散射只增加散射攻击的弹丸；没有匹配武器时仍可启用，但会明确提示当前无武器受益。没有新增协同、道具、素材、平衡或 RNG 变化。共享纯规则计算与背包只读视图，具体语义见 [v25 说明](docs/V25_TAG_SYNERGY_PROGRESS.md)。本批已通过固定源码回归、独立权威等价、受控原生界面与精确 PCK 的有限实际操作验收；初次生产源码冷导入和最终复用缓存再验证分别记录。不是完整通关、Windows 或音频验收。

## v24 武器数值读数（历史）

本批只修正武器比较界面：商店显示明确的基础数值，已装备卡片显示当前主命中伤害、攻击间隔与实际适用射程；不再把初始玩家的 15 / 0.4 当成所有武器的伤害/间隔。界面与战斗复用同一组纯计算，未改武器、模块、平衡、交易或 RNG。基础行为文案与当前读数分开，弹丸、锥形、旋转、榴弹和回旋/反弹路径使用不同单位，不声称 DPS 或后续连锁总伤害。见 [v24 说明](docs/V24_WEAPON_READOUTS.md)。候选已通过有限源码原生卡片审查；最终冷回归和新 PCK 验收仍以本批最终证据为准。

## v23 边界弹道构筑（历史）

本批新增 Bankshot Driver 与唯一模块 Bounce Guide。弹丸沿矩形场地边界最多反射两次，每段命中额度用尽后变暗滑行，碰到真正的边界才重新装填；Guide 只在第一次反射时改变一次方向。900 是整条轨迹的基础总长度，不是每次反射都刷新，靠近场地边缘走位才更容易发挥。精确合同与候选验收状态见 [v23 说明](docs/V23_BANKSHOT.md)。同时带入已验收的 v22 文案澄清，不改旧装备数值或模式政策。已通过本批独立源码、精确 PCK 与有限 Linux 原生操作验收；GitHub 远端发布须另行授权与读回，不由本地验收推断。

## v22 构筑描述校正记录（历史）

只校正已复现的四处说明文字：武器伤害与固定模块伤害的区别、叠加攻速公式，以及 Cryo/Fracture 的修正兼容边界。没有伤害、计时、RNG、交易、素材或新内容变化。见 [本批说明](docs/V22_MODIFIER_COMPATIBILITY.md)。已通过源码冷回归与受控原生卡片布局验收；这是源码校正，不是新 PCK/程序更新，当前可运行成品仍为已验收 v21。原 v21 交付保持独立不变。

## v21 冷凝与碎霜记录（历史）


本批仅新增 Cryo Sprayer 与 Fracture Coil：短锥形冷凝标记，由另一种武器的主命中消耗标记触发单体碎霜；不是第二个爆炸/连锁数值复刻。已通过本批独立源码、打包集成与有限 Linux 原生流程验收；GitHub 发布状态另行核验，不把本地验收写成远端已更新。精确语义、先后顺序、前置条件与验证边界见 [v21构筑合同](docs/V21_CRYO_BUILD.md)。旧版本素材/模式/既有装备定义保留。

## v20记录（历史）

本批只调整战斗HUD的透明度、文字描边和Boss状态行布局，针对下沿Boss面板遮挡玩家与预警的问题；不改碰撞、伤害、AI、技能几何、时间、RNG或素材。具体测试和实际窗口验收边界见 [v20说明](docs/V20_HUD_READABILITY.md)。

## v19记录（历史）

本批加入固定Godot4.6.3模板校验、隔离冷构建、Linux/Windows x86-64预设及PCK动态资源校验，不改v18玩法、素材或输入。Linux独立可运行包与Windows“已导出但未在Windows运行验收”包分别交付；源码仓库不放平台大二进制。见 [导出与复现说明](docs/V19_DESKTOP_EXPORTS.md)。

## v18记录（历史）

本批只修正crawler既有受击九帧的固定列横向对齐，以及商店/背包价格、槽位和叠层的整数显示；不改源PNG、战斗权威、交易数据或时间。范围与验收边界见 [v18说明](docs/V18_REGISTRATION_AND_NUMBERS.md)。

## v17记录（历史）

本版把清场地面经验升级放到商店之前，消除Deploy后立即补弹升级页；商店优先显示购买/替换按钮，详细概率和机制说明可展开；Core真正summon使用独立16帧，原ring保持。范围及v16数值估算纠正见 [v17说明](docs/V17_FLOW_AND_SUMMON.md)。最终验收未写成全游戏完成。

## v16记录（历史）

本版修复标题seed跨设置/图鉴丢失、设置页Esc不能返回、失焦不暂停及HUD目标被遮挡；为Warden真实冲锋新增独立16帧，原blast砸地保持不变。已有真实云端Linux窗口验收，不把headless当作GUI；Windows导出与真人平衡验收仍未完成。范围、合同、回归及剩余问题见 [v16说明](docs/V16_PLAYABILITY.md)。

## v15记录（历史）

本版从已发布v14 commit `51a6f3ce4ae91e08212c7675df9a9f21620fee9f`延续，仅补Core的hurt9帧/0.27秒、death16帧/0.72秒。至此五种普通敌人和两Boss都有独立受击/死亡反应图；**这不是所有招式/整款游戏完成**，原攻击与所有玩法权威不变。本轮到反应层完整性里程碑收口，不继续扩新功能。见[Core合同](docs/CORE_REACTIONS.md)及[当前覆盖与GUI/手感未验项](docs/REACTION_COVERAGE.md)。

## v14记录（历史）


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
当前包含 **8 武器、28 道具、4 武器槽、构筑加权刷新、五种普通敌人与两 Boss**（已验收 v22 的 7 武器/27 道具定义保留），以及 [此前动作覆盖与本版修正](docs/ACTION_COVERAGE.md)、[六种像素 VFX](docs/PIXEL_VFX.md)、[装备刷新](docs/SHOP_AFFINITY.md)、[道具机制](docs/MECHANISMS.md)、[敌人/Boss](docs/ENEMIES_AND_BOSSES.md)、[经济](docs/BUILD_SYSTEM.md) 和 [UI](ui/README.md)。五种普通敌人和两Boss已有独立受击/死亡图；crawler/flanker接触攻击仍为程序化表现。v16新增Warden独立冲锋，v17新增Core独立summon并保留原ring；没有增加音频、存档或联网。

所有分包请按 [合并解压说明](docs/DELIVERY.md) 放到同一父目录；完整单包直接解压。

## 运行

1. 安装 Godot 4.6 标准版（非 .NET 即可）。本次实际版本为官方 **4.6.3**。
2. 解压后在 Godot 项目管理器选择 `project.godot`，导入后按 F6/F5，或者命令行 `godot --path .`。
3. 标题界面选择 ARENA SURVIVAL 或 ROOM ENCOUNTERS，输入整数 seed，然后 START RUN。只有标题允许切换模式；切换保留当前输入 seed，新局不会继承上局构筑。

这是**可导入的完整源码工程**，不是 Windows 安装包；没有运行 Windows 导出或真人平衡验收；v16已开始真实Linux窗口操作验收。UI 暂为英文以避免系统中文字体依赖，中文说明见本文。

- WASD / 方向键：移动；自动瞄准最近敌人发射。
- Space：短距离冲刺，2.5 秒冷却，冲刺期间免疫接触伤害。
- 标题/暂停的 DISPLAY SETTINGS：降低受击提亮与特效透明度，仅会话内生效。
- Esc：暂停/恢复或退出设置；I：查看构筑/关闭背包；鼠标点击或数字 1/2/3 选升级。失焦时自动暂停，返回窗口后需要明确恢复。
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

**v23（2026-10-25）：**作者与独立冷导入 + 70 个独立脚本入口均通过（各 71 项），251 个声明测试输入不变；Python 负测 3 项、美术资源 27 项、精确 PCK 823 项通过。独立轨迹 234、接触/Guide 62、实际管线 96、目录/交易 347 项检查通过。既有 7 武器/27 模块定义与旧装备 7,680 步权威轨迹、过滤旧池 600 次刷新/612 次交易探针一致；新增商品会有意改变跨版本商店序列。

独立 Linux 成品的 CUA 键鼠自动操作（无构筑/货币注入）在计划 seed 86 的首店赚得 122 scrap，购买 Guide 26 + Bankshot 42 后剩 54，保留 Rivet；第二波观察到实际上边界接触与连续向场内运动的弹丸位置，构筑显示 ACTIVE。受控源码窗口另验收双模式、960/1280、两方向及武器/界面反馈。没有从琥珀色接触截图推断 Guide 重定向、伤害或击杀归属，也不是完整 v23 通关、Windows、音频、全组合或真人平衡认证。详见 [最终独立报告](docs/validation/independent-v23/QA_REPORT.md)。

**v21最终（2026-10-25）：**作者与独立冷导入 + 63 个脚本入口全部通过（各 64 项），233 个测试输入未变；Python 负测 3 项、美术资源 33 项、精确 PCK 790 项通过。独立普通 Linux 操作在 seed 433 的首店从 122 scrap 购买 Cryo 44 + Coil 28，保留 Rivet，显示 Cold Snap ACTIVE，部署后观察到锥形喷射与冷凝标记。受控双模式/两方向素材及碎霜表现另有证据，不把截图当成原生 16 伤害测量。新增商品有意改变同 seed 的商店序列；旧装备范围内的权威轨迹与过滤后的旧商品池回归一致。详见 [最终独立报告](docs/validation/independent-v21/QA_REPORT.md)；不是完整 v21 通关、Windows/音频或真人平衡认证。

**v17最终（2026-10-25）：**作者与独立cold import及55入口全通过，运行输入hash零变化；实际Linux窗口核清场升级先于商店、首屏购买、键盘详情/交易/返回、完整Rooms结果，以及真实Boss尺度Core两方向召唤/受击返回/原ring。原生截图只证明受控逐阶段姿态，不冒充连续录像或真人手感。见 [v17工程报告](docs/validation/v17-flow/QA_REPORT.md)。

**v16最终r2（2026-10-25）：**作者与独立fresh-copy cold import及51个测试入口全通过，运行输入hash零变化；实际Linux窗口已核输入/失焦、HUD、完整三房间普通操作，以及受控Warden两方向动作/中断/预警可读性。初稿虽通过headless但未通过视觉验收，已明确留作拒绝记录；最终证据见 [v16报告](docs/validation/v16-runtime/QA_REPORT.md)。Windows/真人平衡仍未验。

**v15反应层收口（2026-10-24）：**最终镜像安全metadata下，删缓存cold导入及46测试入口全通过；Core作者56项、独立403项、旧动作精确集合343项。164旧权威/配置/资源/场景/UI字节不变，runtime `.gd` 零改；同种子与包后验证见[工程报告](docs/validation/v15-core/QA_REPORT.md)及[独立报告](docs/validation/independent-v15-core/QA_REPORT.md)。以下v14及更早仅为历史。GUI/真人手感/Windows未验，见[收口清单](docs/REACTION_COVERAGE.md)。

**v14守门者反应层（2026-10-24）：**删除生成缓存后cold headless导入与44个测试入口全部通过；作者38项、独立942项，旧动作精确ID/帧数回归314项。159个旧权威/配置/资产/UI/场景字节不变，runtime `.gd` 零修改。见[工程报告](docs/validation/v14-warden/QA_REPORT.md)及[独立报告](docs/validation/independent-v14-warden/QA_REPORT.md)。下列v13及更早均为历史结果。没有GUI或Windows导出验收。

**v13 恢复重建（2026-10-24）：**当前最终metadata下 clean headless 导入 + 42个测试入口全部通过，日志无ERROR；包括旧36个测试、新作者/独立接触敌人测试、UI与3个图标检查。140个v12旧权威/配置/资产字节不变；新素材manifest可由源码分析脚本逐字节重现。见 [本次工程报告](docs/validation/v13-rebuild/QA_REPORT.md) 与 [本次独立报告](docs/validation/independent-v13-rebuild/QA_REPORT.md)。以下v12及更早结果仅是历史。GUI与Windows导出未运行。

v12 修订后真正 clean headless 导入，**37 个入口全部通过**：旧33、作者229项、独立610/66/374共1050项。221个已测运行输入前后及干净副本hash一致；142个旧权威/配置/资产原字节不变。仅ActorDirector表现层泛化真实帧数与安全透明padding，不改AI/伤害/生成/RNG。见 [v12独立报告](docs/validation/independent-v12/QA_REPORT.md)。旧九帧候选及死亡顺序修正前的结果未冒充本版证据；GUI/Windows未运行。下列保留历史版本结果。

v11 已真正 clean headless 导入，**33 个入口全部通过**：旧29入口、作者162项、独立608/50/199共857项。206个已测运行输入与独立快照前后hash完全一致；另核3个独立脚本。136个旧运行脚本/权威配置/资产保持原字节。见 [v11独立报告](docs/validation/independent-v11/QA_REPORT.md)；GUI/Windows实玩仍未运行。以下各版结果保留为历史证据。

v10 接地关键帧修订后重新 clean headless 导入与 **29 个入口全部通过**：旧 25 个、作者冲锋动作 130 项、独立权威状态 parity/生命周期/资源 366+30+194 项；191 个已测运行输入 hash 一致，见 [最终独立报告](docs/validation/independent-v10/QA_REPORT.md)。旧动作资源计数断言改为精确批准 ID 集合，其余旧断言保留，原 6 动作和旧资源不改。

v9 真正 clean headless 导入及 **25 个入口全部通过**：旧 20 个、作者模式 70 项、独立模式/边界/配置/策略 42+20+109+9 项。170 个运行源码/资源/import 文件与独立测试快照逐字节一致；6 个独立脚本另有 SHA。见 [最终独立报告](docs/validation/independent-v9/QA_REPORT.md)。未运行 GUI/Windows 验收。

`godot --headless --path . --script tests/test_game.gd`

若云环境默认 HOME 不可写，用独立可写路径：

```bash
mkdir -p ../moss-test-home ../moss-test-config ../moss-test-data ../moss-test-cache
HOME="$PWD/../moss-test-home" XDG_CONFIG_HOME="$PWD/../moss-test-config" XDG_DATA_HOME="$PWD/../moss-test-data" XDG_CACHE_HOME="$PWD/../moss-test-cache" \
  godot --headless --path . --script tests/test_game.gd
```

这不会写用户真实存档；临时测试和初始化只在上述目录写 Godot 缓存。首次导入可以先 `godot --headless --editor --path . --import --quit`，沿用这些环境变量。

历史 v8 最终 clean headless 导入及全部 **20 个脚本通过**，作者装配 159 项、独立装配/几何 217 项及完整旧回归；最终六单图与实际挂点已进入测试。见 `docs/validation/independent-v8/`。仅有导入与行为/矩阵验证，没有窗口实玩。

历史 v1–v7 日志保留。v7 clean headless 导入及全部 18 个脚本通过：作者动作 114 项、独立动作 35 项及完整旧回归。结果见 `docs/validation/independent-v7/`。

历史 v6：v6六类真实特效加载共54帧，作者161项表现层检查及独立130项检查通过，包含逐帧边界、固定锚点/scale、链电端点、回收池、暂停重开、伤害/RNG隔离及预警层级。旧全套玩法、经济、敌人、构筑与UI回归继续通过（193/11/213/28/72/25/20/109/133/35/565/216/26及UI结构）。600帧headless smoke通过。详细证据见 `docs/validation/independent-v6/`，历史结果在对应子目录。

自动测试覆盖有限 seed/升级、真实剪辑长度/区域/统一画布/脚底枢轴、动画速度缓存、场景启动/射击击杀/升级重复点击/六波胜利/死亡重开。日志见 `docs/validation/`（v1 历史保留在子目录）；不要只看进程退出码，Godot 某些脚本解析错误也会返回 0，应同时核无 SCRIPT ERROR/ERROR 且出现通过汇总。

历史v1–v15窗口验收曾 **BLOCKED**：当时云环境 Xorg 无法建立本地监听 socket；一次正常提权启动也在沙箱挂载阶段失败。未绕过权限，未伪造游戏截图。headless 规则通过不等于视觉、手感、性能或 Windows 验收。

## 修改与后续

新房间配置的有限数值/类型/4096 格预算见架构文档，非法输入在分配前拒绝。旧 balance 仍须按有效范围修改：arena 宽高至少 48、tile_size 必须大于 0；waves 与 max_enemies 为正整数、波时长/生成间隔为正数，升级 id 与字段须保持代码约定。本原型不提供任意 JSON 的运行时校验器。添加新的动作时按美术说明生成新九帧 sheet，先检查每帧轮廓/脚底，再登记 alpha 元数据；不要将新动作9张不同立绘当连续动画。后续优先：最终版本真实窗口回归、构筑经济平衡、动作衔接/挂点/遮挡的窗口微调、随机障碍连通验证、声音。

## 检查入口

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_modes.gd
godot --headless --path . --script tests/test_brood_actions.gd
godot --headless --path . --script tests/independent_brood_parity.gd
godot --headless --path . --script tests/independent_brood_events.gd
godot --headless --path . --script tests/independent_brood_assets.gd
godot --headless --path . --script tests/test_core_reactions.gd
godot --headless --path . --script tests/independent_core_reactions.gd
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
