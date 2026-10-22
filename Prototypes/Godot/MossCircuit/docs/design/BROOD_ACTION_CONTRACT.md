# v12 Moss Broodkeeper — 单敌人动作合同

v11已发布并616文件全读回，commit `04ab91d2ec3c7777d8276def66bddb766b28654a`。v12新目录独立，不改v11冻结文件。本规格基于实读v11 EnemyAI、CombatRuntime、encounters和动作覆盖表，以及实际查看旧brood_keeper.png。

## 价值排序与本批范围

1. **Broodkeeper召唤者**：真实warning/召唤尝试/recover完整生命周期尚为程序化；补身体动作可解释召唤循环，并覆盖不同于射击的子体上限/归属/父死语义。选本批。
2. **Crawler**：最常见追踪甲虫，后续优先hurt/death可读性；没有真正技能前摇，不因制作攻击原画创造可躲窗口。
3. **Flanker**：侧袭路径独特，但hurt/death仍程序化；后续补齐，不同时扩。

仅新增brood_keeper_summon十六帧、brood_keeper_hurt九帧、brood_keeper_death十六帧；保留旧walk/idle。不新增召唤物类型、技能、职业、地图、音频、存档或运行框架。因用户澄清帧数要求，允许最小泛化ActorDirector的真实frame_count读取/分段上界；权威战斗脚本仍零变化，沿arena/rooms共享战斗与ActorDirector。

## 权威玩法保持

- brood_keeper：HP75、speed22、damage11、XP12、scale1.35、cd6秒、warning.65秒、summon_limit3。靠近玩家170范围内向后移动。
- EnemyAI warning到期发summon事件，普通怪count1，切recover并设recover_left=.7。既有branch tick不分摊跨段余时，不借动画优化改逻辑。
- CombatRuntime计算同parent_id且hp>0的孩子数量，按limit余量建立spawn_requests；末尾通过原_spawn_kind("crawler",pos,parent_id)生成，仍受global max_enemies约束。原child位置为父pos+半径50、既有elapsed/index角度，不改为图片管口位置，不消耗新RNG。
- **帧7表示‘召唤尝试’，不等于保证一个孩子出现。**3活子体满额或全局满额时身体仍完成原循环，不能烘焙/补发新子体或召唤实体影子。真正实体只由原spawn链创建；动画不得建立延迟spawn队列。
- warning/recover仍接触安全；move接触伤11、碰撞半径16×1.35+9=30.6照旧。动画不加受击硬直、无敌或额外攻击。
- 父体hp<=0立即退出combat、奖励一次；尚未到期warning被取消。**已存在的子体不会因父死自动消失**，仍是活敌并阻止rooms清场。父体死后尾播无召唤/伤害/奖励权限。不要错误清理子体来让测试通过。

## 美术与分段

|资源|真实动作语义|时序|
|---|---|---|
|brood_keeper_summon|16帧：0中性接地；1–3撑足；4–6巢壳蓄动；7结构发力代表尝试；8–11松弛、12–15渐稳|warning0–6(.65s)，recover7–15(.7s)|
|brood_keeper_hurt|0中性→短后撤/巢壳晃动→回稳|原hurt .27s|
|brood_keeper_death|16帧：0中性且接地；1–3失力；4–7屈足下沉；8–11侧伏压低；12–15落定余震渐稳|原death .72s|

旧源身份：左向三分之四、苔绿厚甲、奶白小面/两个黑竖眼、黄铜/橙金短机械足，背负**五孔金口沿蜂巢管束**。不得变新昆虫/新生物/炮台。召唤图不烘焙孩子、弹体、攻击轨迹、光柱/大光晕；原警告圈及真实crawler实体独立。不能画出子体轮廓后在满额时仍显示其出现。

修订实测summon/death逻辑canvas为313×360，hurt为418×360；各clip anchor均[.5,330/360]。每clip首帧中性站姿reference_height，统一到旧walk可见身高（不是PNG透明画布）。全clip同scale/anchor，禁止逐帧bbox自动居中/缩放。death0/1必须接地；明确生成漂移可用作者指定少量裁片原点补偿，保存alpha>8实体不裁切/不带邻格，不消除倒下真实压扁。三图须实看并重算41帧alpha、参考尺度和接地点。

## 表现合同

profile brood_keeper: attack=brood_keeper_summon,hurt=brood_keeper_hurt,death=brood_keeper_death；phase_driven_attack=true；phase_frames warning[0,6],recover[7,15],attack[7,7]；locked_aim_states[warning,recover]。复用现有observe_enemy，不加新的事件派发/定时器。

正常warning最后时刻帧<7，真实召唤尝试同tick进入recover进度0/帧7；如果允许生成，此tick也有新child。满额仍帧7但无假实体。contact attack不得重启或伪造召唤。hurt覆盖时AI和真实尝试继续；hurt结束显示当前recover/已回move，不能补播7或迟生孩子。锁aim近垂直保留旧镜像，不因玩家绕背翻转；death固定最后方向。

暂停/背包冻结表现和玩法。rooms清场按活敌数与有限计划耗尽，不能把父体死亡当完成；可保留合法视觉corpse尾播但无活战斗作用。title/retry/切模式清旧run对象，无迟到spawn。

## 独立验收

- 两模式新profile与移除profile fallback同seed同输入轨迹：父/全部子体id,parent_id,kind,hp,position,AI/计时；全弹体、拾取、玩家、构筑、奖励和三个RNG逐tick一致。真实至少两次summon尝试，不用纯纸面计算称实玩。
- 正常生成一child、3活子体满额不生成、死child释放名额、全局满额不生成；动画不得越过任一cap。child出生位置按原半径50/时间角度，不按源图管口。
- warning受击跨尝试仍准时；hurt恢复不补生；重复contact/observe不重复子体；低帧跨阈值仅按原tick一次。
- warning父死取消后续尝试；已有child保留parent_id继续存活/阻止roomclear；真实清掉剩余孩子才结算；暂停/重开/切模式不泄漏spawn或奖励。
- 三资源实际加载、41帧/固定尺度/接地/正确分段；全部旧入口与新作者/独立入口clean import回归；源码资源hash锁与完整ZIP/分包/manifest逐byte审计。

限制：源PNG为高分辨率像素风/卡通sprite，不宣称严格原生低分辨率pixel art，nearest不自动改变素材性质。实际GUI/手感未验，不称全游戏动作补齐。本版本发布由root完成与回读。

## 用户澄清后的执行版（17:30 UTC，覆盖前述旧画布建议）

用户说明九帧只是便于生图而非硬要求，动作应有十几帧。root/美术/策划锁定**16/9/16**，不是初议15或2×9凑18。summon/death各单张4×4，hurt保留原九帧。美术按新源图实际尺寸重新定各clip固定canvas/anchor/reference，不强沿旧418×360/330；death首两帧接地要求不变。单图避免多页尺度/身份漂移，本批不为展示多图加载能力强制拆图。

旧九帧候选、规格、脚本与中间610/62结论保留于history-nine-frame，已被取代，不作为16帧版验收证据。新源码/资源要重新全回归及锁hash。

- warning七姿态0..6按真实.65秒均匀映射；attempt/recover九姿态7..15按真实.7秒映射；hurt九姿态/.27，death十六姿态/.72。不增加AI时长或死亡战斗权限。
- 低帧率可跳过中间姿态，不补播队列、不保证每次渲染看全16；有效期内按当前age映射到N-1，到期仍按旧规则收尸。确定性单元采样验证全部16真实源姿态可达。
- 不能复制帧/只改元数据凑数；源图实看连续姿态，像素hash不同只是辅助不是动作质量证明。旧所有九帧图原字节保留，旧语义回归不可放宽。

## 实际16帧资源与单图读取合同

- reference_height summon225 / hurt269 / death206，取各源中性站姿，不取PNG整幅/透明边距。统一到既有walk世界身高。每clip固定scale，不因蹲伏/压扁逐帧反向归一。
- 4×4源图实际行距不同，使用每整行固定安全region及标准AtlasTexture.margin透明padding。margin为[left,top,total_extra_w,total_extra_h]，逻辑canvas=region.size+margin.size；alpha_bbox已经含padding.position，禁止重复加。无PNG像素修图、无逐帧bbox居中。
- ActorDirector仅泛化合法N=2..256、分段范围N-1与margin；单clip单PNG。frame.path明确拒绝而非静默忽略；多图加载本批未实现/不需要。旧九帧资源、计时、source标记保持。
- 安全门禁：region源内、非负有限整数；margin非负有限整数且offset<=extra；全clip逻辑canvas一致且每轴<=4096；alpha_box在逻辑内容区域。独验覆盖非法类型/NaN/Inf/边界而不实际分配超大图片。
- 已独立逐像素核41记录：alpha>8的全部源像素恰被一个裁片覆盖，逻辑bbox按crop+padding一次计算，首中性与death0/1脚底330。此数据QA不替代逐帧实际观看。
- 17:49已关闭death原源3→4非设计性+14源像素增高：显式作者source_order为[0,1,4,5,2,3,6,7,8,9,10,11,12,13,14,15]。策划与美术分别实看站立失力→前腿屈曲→壳低俯→持续伏落；不是自动按bbox排序。原16完整region/margin/alpha记录各一次，PNG/anchor/reference不变。新高度序列[206,203,203,193,192,189,188,175,171,163,164,159,119,120,117,110]，最大相邻增加1源px；原14px反站消除。旧被拒序列存history-pre-death-reorder。
- summon11姿态高度169/225≈75%，仍有机械腿支撑；12回216/225≈96%，属于尝试后回稳，并未完全倒地再复活。承认生成节拍较明显，未宣称连续播放达到手工精修程度。
