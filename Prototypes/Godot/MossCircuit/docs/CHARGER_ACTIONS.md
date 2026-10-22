# v10 冲锋者动作切片

只补冲锋者（charger）这一种普通敌人的动作缺口，不冒充五种普通怪都完成独立动作。本版没有改地牢、商店、武器、数值或敌人 AI。

## 权威状态 → 表现

`EnemyAI` 仍决定 warning（0.65 秒）、charging（0.6 秒）、recover（0.8 秒）及接触伤害。`ActorDirector.observe_enemy()` 只读取其当前状态、剩余时钟和已锁定 aim，更新 sprite 与自己的表现缓存。`CombatRuntime` 用它替换原来的内联视觉段；没有由帧回调产生移动、伤害、掉落、奖励或再次释放。

`data/actor_actions.json` 的 charger profile：

| 实际表现状态 | 素材 | 帧段 | 推进依据 |
|---|---|---|---|
| move / idle | 原 charger walk | walk 0–8 / 首帧 | 旧走路表现计时 |
| warning | charger_charge | 0–3 | `1-warning_left/warning` |
| attack（charging） | charger_charge | 4–6 | `1-charge_left/charge_duration` |
| recover | charger_charge | 7–8 | 真实进入恢复时捕获 recover_left，此后按剩余时间比例 |
| hurt | charger_hurt | 0–8 | 原共享受击表现时长 0.27 秒 |
| death | charger_death | 0–8 | 原共享死亡尾播 0.72 秒 |

三个段合计九帧，不是把走路当攻击，也不是每段都声称独立九帧。实际 AI 时长优先，动画不能延迟或提前碰撞。低帧率可以跳过视觉采样帧，不补发任何逻辑事件。

- `phase_frames` 是 profile 数据；没有在 main 中按 charger 写特例。缺少已批准图时仍有明确共享程序化 fallback。
- `phase_driven_attack` 阻止接触反馈重新播放冲锋；原先移动状态接触仍可造成伤害，但不伪装成发动了新的蓄力冲锋。
- `locked_aim_states` 指定 warning/charging/recover 按已锁定方向镜像，不追着绕背的玩家翻转。接近垂直时保留上一次朝向，避免抖动；move 继续朝向玩家。
- hurt 只盖住画面，不暂停 AI。期间不断接收真实 phase/progress，结束后显示**当时的真实段**，不重播已过时前摇。
- 死亡立即退出战斗并结算一次，尸体尾播不保留攻击能力。沿用 v9 的短暂纯视觉尸体保留与上限，结算可保留未结束尾播；标题、新局、切模式清空旧尸体，不能有迟到回调控制新局。

## 素材约定

追加 manifest 仅允许新增 ID，不覆盖原六个动作。动作按固定画布、固定脚底锚点切片；reference_height 来自中性站姿，不用逐帧包围盒重缩放。death 首两帧有一次显式作者接地校准：region.y 从 70 改成 59/63，把原非有意的 11/7 源像素悬空消除；PNG、固定画布、统一 scale、anchor 与其余帧不改。这不是运行时逐帧 bbox 自动归一，证据见 [校准说明](art/charger/CONTACT_FIX.md)。

原 walk 与已验的主角/Boss/武器/VFX PNG 不重画、不改字节。素材来源与逐图边界以 `docs/art/charger/` 的最终生产者记录为准。

旧动作测试唯一需要的版本更新是“资源恰好六个”改为精确的当前批准 ID 集合；原六个 ID 仍全部必须存在，其他旧断言保留。新增资源还须九帧有效、固定画布和 manifest 一致检查，未批准 fallback 图不得计入运行资源集合。

## 验证边界

[最终独立报告](validation/independent-v10/QA_REPORT.md) 已核原 25 入口、作者 130 项、独立生命周期/资源和两模式表现开关比较共 590 项，以及 191 个冻结运行输入 hash；接地校准后已重新 clean import 与 29 入口全通过，最终证据为 grounded_*，旧 final_* 只留历史。比对包括敌人 AI/位置/HP/aim/时钟、玩家生命/奖励和 RNG；不是实际渲染验收。GUI/Windows/手感仍 NOT_RUN/BLOCKED，不使用伪造运行截图。

## 仍缺什么

另外四类普通敌人的独立攻击/受击/死亡原画、Boss 专属受击/死亡、声音、窗口视觉/可玩性及长期平衡，均未由本批补齐。已有数据入口可逐种追加，而不是一次承诺全部美术完成。
