Moss Circuit v38 — Stitch Drone / editable SVG revision

本包是 Linux/Windows 共用资源 PCK，不是新可执行文件。请使用既有 MossCircuit.x86_64；Windows 原生执行未验证。PCK SHA256：
b8f648cc2f9378dfffc162375e105dd2e5ccd21044cb6496e4ebe39027a38740
大小 42,955,188 bytes；15 个连续分块。正式无人机素材为手写可编辑 SVG 的确定性 PNG 导出；旧 AI 图片仅历史参考，不在本 PCK。

在下载的完整仓库根目录先验证：
python Deliveries/MossCircuit/restore_deliveries.py --version v38 --verify-only
再恢复到全新目录（不覆盖既有文件）：
python Deliveries/MossCircuit/restore_deliveries.py --version v38 --output ./restored-v38
工具只重组/校验文件，不自动安装、解压或执行。保留原 v37 PCK 备份后，才能自行替换已有程序旁的 MossCircuit.pck；需要回退时恢复备份。许可证及原可执行程序要求不变。

玩法：新增可中断的单目标支援修复敌人。它不能修复自身/同类/boss/召唤子体；受到实际正 HP 损失会打断引导。死亡和击杀/拾取 proc 在末阶段修复之前结算，致死优先。Arena 的后续生成轨迹、Rooms 指定关卡阵容有明确扩容，不声称新旧随机轨迹一致。

验证边界：逻辑候选完整139路线通过并由另一人逐原始日志独审，保留48条既有draw_rect警告。旧135/138失败、作者初始夹具失败、死亡清理2失败均留档。音频权限原单180秒超时未改写为通过；新Arena435/Rooms338分别180秒，总360秒，是不同测试预算。原timeout部分输出未捕获，未伪造。

本次重绘仅做受影响验证：source120/418/35、packed121/418/35，以及4组合×7步=28实际Runtime原生观察全部通过。29原图含1额外迟后观察，不是29语义case。没有把旧generated-art完整139或旧普通局作为新像素重跑结果。
旧普通局一次默认seed/Rivet/Rooms在首个自然CROSSFIRE无人机交互后结束，击杀无人机，未见自然修复成功；没有换seed或注入状态重刷。物理可听输出与Windows原生未验证，Dummy内部capture不等于听音。

既有modal键盘焦点可到HUD的问题另有诊断；修复属于后续扩容版本，不混入本冻结PCK。本次原样helper恢复/拒绝覆盖/篡改负控/实际本地v37备份回退的结果由独立凭据记录。GitHub发布需真实提交和读回，不由本地验收推定。

发布包装修订：原重绘 PCK 的素材测量记录含 8 个执行器绝对路径，公开包装隐私门禁拒绝，未发布该包。独立候选仅将这 8 个命令路径改为相对路径，并同步修复导出 recipe 的记录方式；真实导出参数、SVG/PNG/数值不变。重新导出时原“仅一条 payload 改变”严格门禁仍因场景身份字段变化而失败，原失败保留。
最终新包完整 219 条资源中，217 条 payload 完全相同；另外仅测量 JSON 的 8 个路径、单节点 main.scn 的 node_ids[0] 从 106410627 到 707380806（684 字节中仅偏移 508–511 四字节）改变。这个字段是真实场景身份，不是填充字节；其他 680 字节及其他 10 个 bundled 字段相同，例外仅限本次精确两个包，不忽略未来 scene ID 变化。全包隐私扫描无命中。
新包再次通过通用资源验证、专用 121 资源/Atlas/像素检查及一次正常原生主菜单启动/退出（21.053 秒，既有 VSync 警告保留）；未将这次包装修订称为重跑 28 步或普通局。
