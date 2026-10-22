# v9独立验收计划

本文件是测试方案，不是已通过报告。针对作者正常路径以外的中断、重复与跨模式反例。程序候选稳定后实读diff、运行既有测试、逐条记录证据；不得改弱既有断言。GUI/真人手感当前未测且不得绕过sandbox尝试。

## A 保持既有承诺

1. catalog仍6武器26道具，slots=4/8，affinity正探索权重/无放回/固定seed序列保留。
2. 全部既有headless测试（含ui/test_ui.gd）在v9执行，输出保留原始退出码、PASS计数、stderr；发现失败先归因，不以删断言通过。
3. 实读diff确认Rules/Effects/武器/敌人/动作不为新模式复制或偷偷改数值。Survival仍6×30秒，第3/6波Boss双门。

## B 新模式有效而非皮肤

4. rooms第一帧enemies为空且尚待生成：_complete_wave不得奖励/前进；全部计划耗尽但活敌>0也不得前进。
5. 把房间时钟推过30秒但留一个活敌：仍在同房；清完所有敌人并生成计划耗尽后应立即进入升级/商店，不等30秒。
6. 召唤怪产生的活子体也阻止结算；固定计划不会因常规无限spawn_clock额外刷怪。
7. 前两房保留build/金币/等级/有效HP政策，最后一房胜利；无第4房或最后多送一个商店。
8. HUD清楚显示模式、房号、待生成/剩余敌人目标；结算结果标识当前模式，不把room叫wave而误导。

## C 重复与跨模式反例（高优先）

9. rooms完成第一房后连续两次_complete_wave：金币/升级次数只加一次；商店continue双击不跳两房或生成两份计划。
10. arena商店保留generation→退标题→rooms新run→rooms商店→传旧buy/refresh/sell/continue：均无货币/货架/阶段改动。
11. arena升级保留choice_generation→退标题→rooms升级→旧_take_upgrade：不能选中新房间升级；旧effects epoch事件不能产伤害/治疗。
12. 尝试playing/paused/inventory/shop/upgrade/dead/won的_select_mode：拒绝且mode/build/phase不变；title合法切换。
13. 修改build.items/levels/coins_fraction、护盾/回声/医疗/电荷、Boss奖励去重、待爆炸/余烬、shop_pending、upgrade_pending，再arena→rooms→arena；每次新run彻底清零至合法初值，显示设置允许保留。
14. 每模式连做两次retry，同seed货架/阶段计划一致、选择模式不丢；new_seed不重置回arena。
15. 死亡尾播中退标题再开rooms，推进超过旧result_wait：新run不出现旧死亡结算，也没有旧尸体/武器。
16. 房间还有一名敌人→暂停→背包→关闭→设置→关闭→继续：待生成数、目标、时钟/计数未被模态推进；继续后敌人仍需击杀。
17. 非法mode id不部分改状态；同模式重复选择/标题重复点击不得积累节点、怪物或奖励。

## D 人工GUI验收（需可用授权环境，当前未执行）

模式选择键鼠焦点；三个房间有清楚可读目标且过渡不闪跳；死亡/胜利/重新开始文字无遮挡；战斗四武器+Boss危险边界可辨；低闪光不抹掉危险语义；实际完整通关与失败路径。记录配置、seed、构筑、耗时/伤害/失误点、截图或录屏。没有这份证据只能说headless逻辑通过，不能说已实玩或平衡完成。

## 通过标准与发布门

所有既有断言通过、新模式反例证据成立、模式共享层无重复实现且文档准确。GUI缺口必须保留。本组无远端写授权任务，不宣称v9已上传；仅父任务核对远端commit后可更新发布状态。

新增清理反例：房间清空后残留召唤请求/敌弹/迫击炮不得越过阶段边界，再次触发奖励；清理信标只能表现，不得发结算事件。若引入0.6秒清理state，入口应立即关闭战斗，重复complete不重启timer、不发双奖励；title/retry后timer不能覆盖新局。候选PNG已标记视觉失败，生产默认必须按manifest使用geometry fallback。
