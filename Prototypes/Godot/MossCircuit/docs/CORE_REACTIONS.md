# v15 Core反应层与本轮收口

本批从已发布v14 commit `51a6f3ce4ae91e08212c7675df9a9f21620fee9f`延续，只补现有Wave6 Spore Reactor的独立受击/死亡。没有新Boss、技能、攻击variants或额外战斗事件。

## 新动作

- `boss_core_hurt`：9帧，0.27秒；实际HP损失触发，重复hurt不重启，结束回当前权威phase。
- `boss_core_death`：16帧，0.72秒；覆盖其他反应，终态不可重启，尸体纯视觉，不产生伤害/召唤/奖励。
- 动作固定逻辑画布、reference_height与anchor；保留源姿态偏移，不逐帧bbox归一。Core为浮体，anchor连续不应被误称每帧实际脚底静止。

## 原AI/释放规则不变

warning0.85秒，释放后recover0.7秒。phase1环弹8发；HP≤50%为phase2，选招时仅pre-increment `attack_index % 3 == 2`取summon，其余取ring，不能简化成两招交替。ring在释放tick按当时phase产生8/12发，summon尝试1/2只，同时受父体3只活子体上限和全局实体容量约束。warning中跨半血不因hurt改变真实释放判定。半血速度/冷却变化沿用原数据。

hurt覆盖身体不延迟、取消或重复ring/summon。父体死前已发生的伤害不回滚；父体在释放前死则不补放该招。

## 死亡、子体和清场

Core死亡立即退战、清除自己拥有的敌弹、结算一次原有100coins/皇冠奖杯，不授予Warden协议或其修复。**不会凭死亡动画直接杀掉已存在的crawler子体。**

Arena wave6按原`波次计时到达 + boss_defeated`终局结算；活子体可在该正常settlement中被清场，这与父体死亡删除子体是两件不同的事。早杀Core仍等待计时。Rooms没有原生Boss关卡；测试注入Core仅是fixture，子体仍按原房间清场规则阻挡结束。没有新增房间Boss内容。

## 本轮里程碑收口

五种普通敌人（crawler/charger/spitter/flanker/brood_keeper）与两Boss（warden/core）均有独立hurt/death图。九帧只是短反应节拍，不是动作上限：长死亡可16帧。

这只完成受击/死亡反应层覆盖，并不等于整款游戏/所有动作完成。两个Boss仍各复用旧attack9于不同原招式；未补独立招式攻击图或新特效。GUI真实窗口、真人手感/平衡、Windows导出、音效/音乐、存档与联网仍未验或未实现。本轮到此收口，不无限扩展新功能。
