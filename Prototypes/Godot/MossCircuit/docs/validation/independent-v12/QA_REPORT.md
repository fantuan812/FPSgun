# v12 独立验收

## 最终运行候选：PASS（封包待独审）

2026-10-22，干净副本 `/tmp/moss-qa-v12-final` fresh import，**37 个入口全部 PASS**：旧33+作者1+独立3；日志无ERROR/WARNING。不是把九帧候选或死亡重排前的PASS迁移过来。

- 作者 `test_brood_actions.gd`：229 PASS。
- `independent_brood_parity.gd`：610 PASS。arena/rooms各300步，新profile与去profile fallback同seed/输入，比较完整父/子id、parent_id、位置、HP、AI/计时、全弹体/拾取/构筑/玩家和三个RNG。实际至少两次召唤与父死子留存，不是纸面平衡测试。
- `independent_brood_events.gd`：66 PASS。真实3活子体cap、原90全局cap→0新增；真杀子释放名额；hurt覆盖尝试仍按时补位且不延迟补召；接触原伤害11、warning/recover安全；暂停；.95大步仅一次尝试/不重放跳过帧；warning末父先死取消，原活子保留parent_id且阻塞rooms；清完才一次结算、跨模式无旧引用。
- `independent_brood_assets.gd`：374 PASS。精确16/9/16实际加载、完整帧可达、release7同真实尝试tick、满额仍尝试但无假子体、hurt后当前进度；固定reference/scale/锚点与旧walk中性身高/宽度对照；death0/1接地、正常尾播.70可达15且.721过期；N=2/9/16/256及非法N、NaN/Inf/错型/非法region/margin/跨图path拒绝、逻辑4096边界/4097与1e300拒绝，不实际分配巨图。

独立合计 **1050 项 PASS**。测试未修改生产数值或削弱原断言。测试高HP夹具只用于避免比较轨迹中途结束；真实cap、伤害、AI参数未改。

## 图像与死亡顺序修复

实际看过3张新版源图，左向机械五孔蜂巢身份一致；summon只身体发力，无烘焙孩子/生成影子。16/9/16各真姿态，不复制尾帧凑数。

独立Python只读重算41帧：所有alpha>8源像素恰好由一个裁片覆盖；逻辑bbox等于物理crop bbox加margin.position一次；每clip固定logical canvas，neutral reference为225/269/206，首中性与death0/1脚底330。见 `logs/independent_source_alpha.json`。

root拒绝原death3→4高14源px的非设计性回站后，策划/美术分别实看并采用显式作者顺序 `[0,1,4,5,2,3,6,7,8,9,10,11,12,13,14,15]`：失力→屈足→壳低俯→伏落。独验确认原16完整region/margin/alpha记录各一次、三个PNG SHA全未变、anchor/reference不变；最终相邻高度最大增加1源px，不再14px反站。不是自动按bbox排序/逐帧归一。被拒旧序列保存在 `history-pre-death-reorder`。

summon11→12由中性75%低姿回96%，腿仍支撑，属尝试后回稳而非倒地复活。生成姿态存在细小足尖/脸板位移，未宣称手工精修流畅度。

## 代码边界与被测身份

实读diff：仅ActorDirector表现脚本泛化N和标准AtlasTexture.margin；data仅新增brood_keeper profile及manifest；旧动作测试仅精确15 IDs和新两clip16，旧九帧期待未放宽。**142 个原权威/配置/旧素材输入逐byte不变**，包括EnemyAI、CombatRuntime、武器、效果、模式、UI等。旧walk/idle继续复用，未扩其他敌人/职业/地图。

- 被测运行输入 **221 文件**，运行前后及干净import副本hash一致，集合无新增/删除。
- `logs/final_runtime_hashes_before.json` SHA256：`7ea0ad2e88a6f4c0049740b50bc5eb8f88cfb62718c70df5b707ef044401c1da`。
- 3 独立脚本hash见 `logs/final_independent_script_hashes.json`。
- 当前美术manifest SHA256：`be8abe0519f37d30650efd816d094318e21bafdc03ad0ffa3fb7433bb0db2766`。

源图为高分辨率像素风/卡通sprites，**非严格原生低分辨率pixel art**。真实GUI/手感未运行；headless与源图检查不等于窗口整合验收。当前仅运行候选通过，最终ZIP/manifest/分包union仍待独审；发布由root负责，未声称v12已上线。
