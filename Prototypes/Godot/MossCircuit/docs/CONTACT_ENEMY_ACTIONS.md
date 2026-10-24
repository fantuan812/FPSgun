# v13 追踪甲虫 / 侧袭怪动作合同（恢复重建）

## 内容与时序

- `crawler_hurt`、`flanker_hurt`：9 个独立帧，0.27 秒；实际 HP 损失触发，重复 hurt 不重启计时。
- `crawler_death`、`flanker_death`：16 个独立帧，0.72 秒。死亡不可被 hurt/attack 打断；奖励与退出战斗立即发生，视觉尸体最多40个，期限到回收。
- 只读表现：动画不产生伤害、位移、召唤、额外奖励，不消耗 gameplay RNG。受击结束返回当下权威 phase，不回放错过的攻击。
- crawler/flanker 无真实 AI 蓄力阶段。删除 ActorDirector 原距离 `<85` 的两行伪 warning 分支，近身时继续 walk。实际 contact hit 调用仍原样保留，没有暗加前摇或改命中窗口。
- 模态暂停保持动作计时；重开/标题清理旧实例。近身 walk、contact 脉冲、hurt、death 不改变移动与判定规则。

## 美术与恢复边界

四张源 PNG 的旧 Git blob 字节恢复成功，但旧 v13 整包及其验收不能据此视为恢复。工程从精确 v12 的699文件开始；本次重新编制四动作裁片 manifest、接入并实跑回归，旧版本日志保留为历史而非本版通过证据。

死亡使用16个真实姿态与显式作者顺序，不复制帧凑数；固定逻辑画布、reference_height 与 anchor，禁止逐帧独立缩放/重居中。固定anchor连续、首帧身高一致不等于每帧可见脚底不动：最终保留最多12源像素的自然抬脚和横向重心偏移，不声称GUI无跳动。源图像素不修改，仅合法 AtlasTexture region/margin 裁片与透明padding；素材具体坐标/来源/限制见 `docs/art/contact_enemies/`。

## 验收入口

- `tests/test_contact_enemy_actions.gd`：加载/帧数、近身移动/walk、hurt防重启、death终态/末帧/回收和接触触发保留。
- 本次完整回归和独立同种子AI/伤害/RNG轨迹见 `docs/validation/v13-rebuild/` 与 `docs/validation/independent-v13-rebuild/`。
- 仍是完整可导入源码，不是Windows安装包；headless验收不代表真人实玩、平衡或Windows导出验收。
