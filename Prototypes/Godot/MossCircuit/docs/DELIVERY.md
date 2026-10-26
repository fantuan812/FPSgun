# v22 构筑说明校正 — 仅源码增量

本次只交付 `MossCircuit-v22-ModifierCopy-SourceDelta-2026-10-25.zip`：四处已复现的描述校正、兼容说明与相关验证证据。**不是新游戏程序或 PCK，不要把源码增量直接覆盖到成品游戏目录。** 当前可运行成品仍是已验收的 v21，`BINARY_DELIVERIES.json` 保留它的精确身份，不代表 v22 导出。

基线是 Library 的完整 `MossCircuit-v21-ColdSnap-2026-10-25.zip`，SHA256 `bcd562ce8975bf903e16af4a5203ab6089338789b524df78e5b8b7d2bea972bc`，根 MANIFEST SHA256 `6db84a927b27cebfe16770a70036fe6b8979b9e13fa11c039c60d678203fcf25`。先保留原始备份，按增量包内中文说明核对基线，再手动将 `delta/` 内容合并到源码项目根；无删除路径。最终完整文件集合由新根 MANIFEST 逐项验证。可使用 Godot4.6.3 导入运行源码；本次没有重新导出平台包，也没有自动操作用户电脑。

范围：Power Coil 只承诺武器伤害加成，固定模块伤害不变；Rapid 明确每层15%加算攻速，间隔为基础间隔/(1+总攻速加成)，下限0.09s；Cryo 明确瞬时锥形、不吃弹丸专属加成；Fracture 明确固定16二次伤害不随武器加成放大。仅 `data/catalog.json` 和 `data/balance.json` 的四个明确描述字段改变。所有数值、ID、价格、权重、交易行为、脚本/UI代码和素材不变；不声称整个定义字节相同。

作者和独立冷导入+65脚本通过（各66项），236输入不变、Python3、105项文案/字段/布局检查。双模式960/1280原生源码窗口卡片、升级、背包和重复交易导航已做有限验收。修改前84项兼容机制检查及v20/v21旧武器对照证明这是继承的说明失实，而非新伤害/计时缺陷。完整范围见 `V22_MODIFIER_COMPATIBILITY.md` 和 `validation/independent-v22/QA_REPORT.md`。没有新 PCK、完整游戏通关、Windows、音频或真人平衡认证。

历史 v21 源码、运行包、Library 身份和证据保持原样。GitHub 分支仍须按实际授权与读回结果判断，不由本文件推断已发布。
