# v14 守门者反应层合同

本批只为现有 Wave 3 Moss Warden 新增独立 hurt/death，不增加Boss、招式、伤害、前摇或玩法系统。来自已发布 v13 commit `56a6c721850fc3ef67caa0f766661a3970eb6a59`，原工程与原包保持不动。

## 两个新增剪辑

- `boss_warden_hurt`：9帧，0.27秒，由真实HP损失触发。重复hurt不重启；charge/blast的AI、移动、命中和恢复计时继续前进。
- `boss_warden_death`：16帧，0.72秒，由死亡触发，覆盖所有hurt/attack；尸体属于纯视觉，期限到回收。死亡立即退出战斗，既有Boss协议/奖励只结算一次。
- 所有帧保持固定逻辑画布、每动作固定reference_height与anchor；保留源姿态位移，不逐帧bbox缩放/重居中。九帧不是技术上限。

## 不变的权威时序

Warden原AI每次warning为0.85秒；charge实际冲刺0.6秒、随后recover0.8秒；blast在真实warning结束时结算一次、随后recover0.7秒。半血后的速度/冷却规则原样保留。

hurt只是视觉覆盖：同tick受击仍允许本来应释放的charge或blast正常发生，受击结束回当前权威阶段，不补播已经过去的招式。死亡发生在释放前时不会在death尾播中补发blast；已经发生的伤害不被动画倒销。

早杀Wave3 Boss不绕过原波次计时；到达原清场条件后不必等0.72秒尸体才结算。结算/升级/商店等模态的冻结与尸体保留行为沿用旧合同；标题和重开清旧尾播。

## 明确保留的旧表现边界

现有`boss_warden_attack`九帧仍复用于charge与blast，未增加attack_variants、phase_frames或锁定aim新策略；其原图含烘焙效果的限制不被本批反应图掩盖。本批不是“两个Boss全部招式动画完成”：Core的hurt/death仍程序化，Boss各招式独立攻击图、实时窗口美术/手感验收仍未完成。

## 验证

作者入口 `tests/test_warden_reactions.gd` 覆盖真实释放/伤害与hurt互不阻断、致死覆盖、一次奖励和Wave3计时/尸体边界；独立策划/QA以两模式、两血量阶段、charge/blast和同种子权威轨迹另行复核。最终证据见 `docs/validation/v14-warden/`，不得把v13历史PASS替代本批验收。
