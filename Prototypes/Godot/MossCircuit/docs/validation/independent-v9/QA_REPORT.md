# v9独立策划/玩法逻辑审查

状态：最终冻结候选独立验收通过。2026-10-22 16:18 UTC。未执行GUI、真人手感/平衡、Windows导出；本报告不证明发布。

## 直接结果

- 20个既有脚本独立重跑均PASS（19个tests + ui/test_ui），无SCRIPT ERROR/ERROR，均有通过汇总；原始日志在logs/，regression_summary.json记录退出码和尾行。
- 自有 `independent_modes.gd` 42项通过；`independent_room_boundaries.gd` 20项通过。没有改项目程序、旧测试断言或测试期待来过测。
- 两脚本以v9为--path、独立QA绝对路径为--script运行；独立HOME/XDG全在/tmp/moss-qa-v9。Godot 4.6.3 headless。
- 标题/结算原有六波/Wave文案问题已修；最终代码实读确认rooms标题说明三房原型，结果含mode_name及Room N/3。

## 证据覆盖

跨模式旧商店购买/刷新/出售/继续与旧升级generation全部失效；title之外playing/paused/inventory/shop/upgrade/dead/won/settings/codex/room_clear不允许改模式；非法ID不部分改状态；3次交替模式新run清空道具/升级/金币小数余额/效果计数/待升级；死亡尾播不能覆盖新run；retry保持模式seed、new_seed只换seed。

房间起始正确显示3个待生成且空敌数组不能提前结算；超30秒活敌仍阻塞；真实spawn_kind子体阻塞清场；真实迫击炮pending在清场入口销毁；反复_complete_wave在0.6秒前后不重复发钱/重置timer；暂停和背包保持clear_elapsed与elapsed；前两房进入共享升级商店、保留实际power_coil×2与speed升级；重复continue不跳房/重复计划；第3房终局无第4房/商店；终局残留不能发钱/生成；清理中退标题新run不会收到旧过渡奖励。

注意测试中为确定性边界设置敌HP=0并通过真实CombatRuntime死亡回收路径，并非键鼠战斗通关。测试的中断/去重结论有效，不可用来声称难度合适或体验顺畅。

## 代码审阅

实读main新增调用、RunSession/CombatState、RoomMode/ArenaMode、RunFlow、CombatRuntime和ModeStatus；diff确认原rules.gd/effects.gd/enemy_ai.gd/动作/武器挂点模块未改。角色/武器/战斗/效果抽到共享gameplay，main访问器引用同一state owner，房间没有第二套构筑经济。Mode提供有限生成计划、目标/清场门、奖励政策，实际战斗不复制。RunFlow统一拾取/奖励/阶段结算，state先改transition阻止重入。

RoomMode计划耗尽+combat.enemies为空+0.6秒clear_elapsed三门。Arena正式模拟is_due检查时间、can_end检查Boss。旧_complete_wave作为稳定测试入口仍允许测试直接模拟普通波完成，不把它描述成独立时间安全API。

catalog.json / balance.json / encounters.json在审查时与v8 SHA一致：6武器26道具、六波与原数值未偷偷改。旧tests目录.gd内容一致。title选择通过mode.field切换arena/rooms尺寸，未来探索尚无房间图/门碰撞/路径寻路，不能称“完整地牢”。

## 美术门禁

实读ui/mode_status.gd：默认绘制几何像素徽记，未加载带halo的失败候选PNG；progress只改变形状/颜色，没有伤害/奖励/结算事件。两种形状差异不只靠颜色。真实GUI是否遮挡/48px美观仍未验证。

## 最终冻结复跑记录

- 从v9冻结候选复制到 `/tmp/moss-qa-v9-final`，排除.godot缓存做真正clean import；exit0，无ERROR/WARNING。
- 最终25入口全部PASS：原20、作者test_modes（70项）、独立4脚本（42+20+109+9=180项）。最终日志 `logs/final_*.log` 与 `final_regression_summary.json`。
- `final_runtime_hashes_before.json`覆盖170个scripts/ui/data/assets/scenes/tests及project.godot文件（含实际import配置），不把会更新的文档/日志/manifest/cache当运行时。运行前后原v9无字节变化；clean import后的测试副本同170文件也无字节变化。详见`final_hash_verification.json`。
- 冻结hash清单SHA256：`ef3bcded2f9c8c7e621c73b0273a027030bcd86e19af51e64b04ff61b364d86d`。
- 六个自有.gd文件（4入口+2fixture）的SHA在`independent_script_hashes.json`；程序可原字节复制到同一测试子目录，fixture按脚本相对目录加载。
- 架构结论更新：RunFlow已不硬编码下一编号/终局/是否商店，消费Mode.resolution；原arena和rooms体验保持。非法resolution在主入口不破坏任何敌人表现节点。
- 本轮逻辑与配置审查门通过；GUI/平衡/窗口性能/导出仍未验。不宣称远端已发布。

## 追加推进/输入安全审查（16:15 UTC，中间候选）

父任务要求Mode.resolution决定terminal/next_stage/shop/upgrades/coins/heal，已实读实现。新增独立受控策略仅继承Arena并覆写resolution，验证1→3跳目标、不进升级/商店、7币3治疗而非硬编码波奖励、共享combat/session/build不换实例、stage3终局覆盖原count6及终局幂等。另非法NaN decision通过真实main入口，不只调用纯规则。

代码审阅发现main曾在RunFlow验证decision前清表现/queue_free敌sprite；已回传并由程序修复为先settle成功后清理。新增跨process_frame敌sprite存活及经济不变反例在修后实跑通过。修前未执行该反例，不虚构失败日志。策略现9项PASS。

配置109项PASS：所有数值字段NaN/±Inf/非数类型、恶意section/stage/name、position，以及4096格合法/超界、65536轴合法/超界、tile极小/极大。只调用验证函数，不创建巨型网格。最终仍须冻结复跑。
