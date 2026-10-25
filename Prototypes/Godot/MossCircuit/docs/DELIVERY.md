# v18 完整工程交付

完整源码ZIP：`MossCircuit-v18-RegistrationNumbers-2026-10-25.zip`。解压后在Godot4.6.3导入`project.godot`；这是累计源码/素材包，不是Windows安装程序。

基线是已发布且逐字节核验的v17 commit `e5176670b2f478a187f7f98b09554baa3c50a6f7`。全部v17路径及历史证据保留。本批只改crawler既有hurt图的固定列X对齐和商店/背包离散数值格式。

- `MANIFEST.json`覆盖除自身外全部交付文件；无`.godot`缓存、引擎、导出模板、临时HOME或签名密钥。
- 作者和独立冷导入均通过58个独立入口及import；生产输入无测试期间修改。
- 独立真实Linux窗口覆盖完整槽位替换、重复SOLD点击、购买/出售、背包返回、整数与小数格式；crawler两朝向原生尺寸A/B和真实hit-segment管线证据分别注明范围。
- 受控QA夹具、截图和日志在带`.gdignore`的证据目录内；不是自动加载的游戏代码。
- Windows导出/运行、真人完整平衡及完整地牢未验，不以headless或截图冒充。

复现：`python3 tests/run_regression.py --project . --output ../moss-v18-checks`。测试输出必须在工程外；使用新解压工程进行cold import。详见`V18_REGISTRATION_AND_NUMBERS.md`及独立报告。
