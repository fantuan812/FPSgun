# v11 普通远程敌人动作：Violet Spitter

## 范围与单一权威

基线为 FPSgun 已发布 v10 `0260a4fddac838e24ec93b850a3a0a1c2e4fa3bd`。只增加 `data/actor_actions.json` 的 Spitter profile、新动作 manifest 与素材/测试。运行脚本全部逐字节保留；不会把已有 `EnemyAI.tick` 另写一套。

| 状态 | 素材/映射 | 权威与边界 |
|---|---|---|
| 移动/站立 | 旧 spitter 九帧/首帧复用 | 保持约230px距离的旧AI |
| 预警 | spitter_shoot 0–3 | 原 warning .65秒；不射出弹体 |
| 射击 | spitter_shoot 4 | 同一个真实 shot tick，AI进入recover，进度0显示4 |
| 恢复 | spitter_shoot 4–8 | 原recover .7秒，释放瞬间是恢复段起点，不新增动画伤害计时 |
| 受击 | spitter_hurt 0–8 | 共享.27秒表现优先级；下层AI继续推进，结束回当前阶段，不排队补播shot |
| 死亡 | spitter_death 0–8 | 共享.72秒尾播；死亡立即移出战斗/清所属弹体/一次奖励，尸体不再参与战斗 |

`phase_driven_attack=true` 阻止接触触发和旧 warning 转换反馈重播攻击反应；`phase_frames` 为 warning `[0,3]` / attack `[4,4]` / recover `[4,8]`。`locked_aim_states` 为 warning/recover，左右由锁定 aim 决定，近垂直保留上一朝向。

不是插入新的开火前摇：原本的 .65s 预警完全不变。接触仍在原move态按旧规则造成伤害，不能因此画成发射弹丸。低帧率可能跳过原画帧，但不能为播放全九帧延迟或增加真实事件。

## 分层与尺寸

原有一体炮嘴属于这个固定NPC机体身份，不是主角可换装枪械。新身体图不含烘焙枪口火光、射出弹体或命中特效；原敌弹仍由独立战斗层产生/绘制，不改从敌人中心发射的既有几何，也不谎称精确新炮口装配。玩家六武器四槽系统与六种VFX不变。

源图为高分辨率 sprite，沿用像素风意图，但存在平滑边缘/细节，并非严格原生低分辨率逐像素动画；nearest采样不能把这种风格差异变成已解决。

每clip固定画布、脚底anchor和以中性首帧量得的reference_height，按旧walk可见站高等比例显示；不得逐帧bbox自动缩放居中。素材只在独立目视与结构检查通过后接入。

## 生命周期与验证

暂停冻结AI、弹体和表现；hurt不能暂停真实shot。死亡中断反馈，尸体允许在原结算策略下尾播，但重开/标题/换模式必须清理引用。Arena与Rooms使用相同profile，无模式特判。

作者入口 `tests/test_spitter_actions.gd` 检查真实shot与帧4同tick、同tick受击遮挡仍恰好一次、恢复当前帧、暂停、旧弹体权威字段、死亡/重开。独立策划已在全新副本导入并通过33入口：旧29＋作者162＋独立parity608/事件50/资源199，共857独立检查。206运行输入前后与副本hash相同，3独立脚本另核；136旧运行/权威/资源逐字节保持。见 [最终独立报告](validation/independent-v11/QA_REPORT.md) 与 [策划合同](design/SPITTER_ACTION_CONTRACT.md)。

GUI/Windows实玩未运行，不能把headless结构与状态验证称为渲染/手感通过。仍未补齐其余追踪/侧袭/召唤怪全部独立原画，也未增加音频、存档或完整地牢。
