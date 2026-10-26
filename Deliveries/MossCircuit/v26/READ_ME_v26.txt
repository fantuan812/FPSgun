MossCircuit v26 — Feedback Diode / 回馈二极管
GitHub 资源包更新，不是独立可执行程序；不再发送聊天附件。

新增唯一模块（28 废料）：装备后成功开始冲刺，在原有冲刺无敌窗口内真正接触敌方子弹，可对仍存活的原射手造成一次固定 24 点次级伤害。每次冲刺最多一次；擦身、近战碰撞和范围爆炸不触发。不增加无敌时间，不触发主武器命中连锁。与 Pulse Boots 的 CROSSCURRENT 组合是推开近敌 + 反击远程的互补效果，没有隐藏倍率。新道具加入后，同种子商店货物可以与旧版本不同。

一、从本仓库恢复新资源包
在完整 FPSgun 仓库目录运行（需要 Python 3）：
  python Deliveries/MossCircuit/restore_deliveries.py --version v26 --output restored-v26
只校验仓库内分块、不生成文件：
  python Deliveries/MossCircuit/restore_deliveries.py --version v26 --verify-only

帮助程序会校验所有连续分块和完整文件的 SHA-256 / Git blob ID，在 restored-v26 生成 MossCircuit.pck 和本说明。它不联网、不解压、不运行游戏、不自动安装，也不会覆盖已有目标文件。输出文件系统必须支持硬链接；不支持时会明确失败，不会改用不安全覆盖。所有文件逐个原子发布，不保证整批事务。Windows NTFS 的实际执行未在本次环境验证。

新 MossCircuit.pck：41,347,432 字节
SHA-256：59096e791e270250a7c6a314d741d7295100016863be2ba85455795c88017e33
这是完整资源包，不是差分补丁；14 个 Git 存储分块必须先恢复，不能把某个 chunk 当作 PCK 使用。无需再次合并 ZIP 分卷。

二、使用经过校验的原可执行程序
Linux：MossCircuit.x86_64，71,075,864 字节，权限 0755
SHA-256：2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
Windows：MossCircuit.exe，104,659,456 字节
SHA-256：91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6

现有 v19–v25 官方交付使用上述未改变的程序。首次安装请先按 Deliveries/MossCircuit/README.md 恢复 v19 原始平台分卷、核对完整 ZIP 哈希并解压完整平台包，再按下面步骤放入新 PCK；必须保留许可证文件。不要只下载 v26 后尝试直接运行 PCK，不要改用未知版本的 EXE/ELF。

三、手动备份与替换
1. 完全关闭游戏。先校验程序文件符合上述哈希，并校验 restored-v26/MossCircuit.pck 符合新资源包哈希。
2. 在安装目录把旧 MossCircuit.pck 备份成一个此前不存在的名称，例如 MossCircuit.pck.before-v26。确认备份与替换前旧文件的哈希一致；不要覆盖已有备份。
3. 只把恢复出的新 MossCircuit.pck 复制到可执行程序旁。不要替换程序、许可证或其他文件，也不要把存储 chunks 直接复制进去。
4. 启动原程序。Linux 使用 ./MossCircuit.x86_64；Windows 使用 MossCircuit.exe。必须保持程序与 MossCircuit.pck 相邻。
5. 回退：关闭游戏，将新 PCK 移至单独保留位置，再把已校验的旧备份恢复为 MossCircuit.pck；程序与其他文件保持原样。

如果您当前确实是 v25，旧 PCK 应为 40,683,384 字节，SHA-256 a7a9064413fc7bfdc1713f516ffc7d99ad6a2af2aa796089b0ddf1372779d42a。其他已交付版本请用该版本原始校验清单核对，不能把不同版本误称为 v25。旧 ARTIFACT_SHA256.json 只描述旧整包；新 PCK 身份以本说明及当前 CATALOG.json 为准。

Linux 校验示例（在各文件所在目录）：sha256sum MossCircuit.x86_64 MossCircuit.pck
Windows PowerShell 示例：Get-FileHash MossCircuit.exe,MossCircuit.pck -Algorithm SHA256
校验失败时停止替换；不要跳过检查或运行未知程序。

四、操作与验证边界
WASD / 方向键移动，空格冲刺，Esc 暂停，I 查看构筑。显示设置仅本次会话有效，不保存到磁盘。
源码回归、受控机制/界面、精确 PCK 与有限 Linux 原生操作分别记录在源码 docs/validation/independent-v26。原生输入由 CUA 自动键鼠和战术暂停完成，不注入构筑/货币或程序化游戏状态；截图不是精确 24 点伤害或归因的证明，这些由受控机制测试验证。
两个平台预设导出的 PCK 字节一致。此次没有重新编译可执行程序；Windows 是原已校验程序 + 新 PCK，不是 Windows 实机验收。云端 ALSA 不可用并回退虚拟音频，VSync 有环境限制；本次原生启动另记录一条 XServer BadValue 诊断，随后渲染与输入正常，不声称零错误启动、声音验收、完整通关、长期平衡或所有硬件兼容。
有限普通操作已用种子 433 赚取 118 废料，购买 Diode（118→90）及 Pulse Boots（90→62），保留 Rivet，并观察 ACTIVE 组合。第二波观察射手警告/子弹并实际尝试冲刺接触；没有捕获短暂紫色回线，因此不宣称普通操作已证明成功反击或 24 点归因。
