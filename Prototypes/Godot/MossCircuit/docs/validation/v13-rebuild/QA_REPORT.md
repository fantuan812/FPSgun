# v13 恢复重建：工程回归报告

日期：2026-10-24。引擎：Godot 4.6.3 stable。工程以v12 commit `6d393134da0a29a7c62a821abf50440e6d304f25`恢复，699/699 Git blob SHA精确匹配。原始恢复清单见 `restoration-verification.json`。

## 最终实跑结果

最终固定列中心/行ground的4动作manifest接入后，删除可再生`.godot`缓存再冷启动headless import + 42个独立测试入口全通过（0退出、无SCRIPT ERROR或ERROR）。`logs/summary.json`逐项记录退出码/耗时，旁边逐项原始日志。包括tests目录全部38个可执行测试、`ui/test_ui.gd`、三个美术图标检查。两个策略fixture是被测试加载的输入，不是SceneTree测试入口，未单独启动。

新作者接触敌人测试38断言；旧动作测试扩充精确批准名单到19个动作、新death为16帧，其余旧断言保留，285项通过。独立接触敌人测试涵盖两模式、左右镜像、所有帧/固定anchor/首帧身高、hurt重复保护、death终态/末帧/回收、奖励一次性、pause/reset及reduced flashes，具体计数见其日志。

140个旧运行脚本、权威配置与资产保持原字节，详见 `unchanged-v12-authority-and-assets.json`。运行代码唯一改动是删除ActorDirector两行 `<85` 伪warning分支；动作数据新增两profile与两个manifest路径，默认hurt/death时长沿用v12。contact逻辑、AI、移动、生成、奖励、经济与RNG源代码不变。

新图原Git blob恢复，不修改PNG。metadata重现脚本以工程PNG为输入，在工程外写出两份manifest，逐字节匹配已安装版本。最终保留最多12源像素抬脚与横向姿态偏移；通过的是固定anchor连续及首帧身高，而非全部实际像素脚底静止或GUI无跳动。初稿逐帧bbox居中/齐底在review中被拒绝，最终使用固定源列中心与源行ground保留自然偏移；具体像素事实与限制见 `docs/art/contact_enemies/`。

## 遇到并已修复的检查问题

- 第一轮环境继承不可写XDG路径导致引擎退出；已设置HOME与三XDG到可写目录，重新导入/全部运行，未将失败轮作通过证据。
- 旧精确动作ID与帧数白名单未包括4个新增动作，曾失败3项；已扩充精确白名单并重跑，不删除旧资源或弱化旧断言。

## 边界

本次未运行真实窗口截图/真人操作、Windows导出、平衡、音频/存档/联网验收。headless UI/几何测试不等于视觉实玩。旧版本日志仅为历史，独立对比用本次恢复的v12和本次最终候选重新运行，不使用遗失旧v13的PASS。

## 重现

```bash
python docs/validation/v13-rebuild/run_regression.py --output /tmp/moss-v13-regression
python docs/art/contact_enemies/build_metadata.py --project . --output /tmp/moss-v13-art
```

检查器会自动给Godot设置可写HOME/XDG，输出目录必须在工程外。
