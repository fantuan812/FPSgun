MossCircuit v28 — Reserve one shop offer / 保留一个商店报价
GitHub 完整资源包更新，不是独立可执行程序；不发送聊天附件。

商店新增一次只能保留一个未售出报价的构筑规划选择。RESERVE 免费，资金不足或装备槽满也能使用；保留不是拥有，不提供属性、标签、联动或刷新倾向。报价保持原价及原抽取权重说明，跨付费刷新与后续商店保留；代价是占用一个货位，原有 5 scrap 刷新费只换来另外三个新报价。RELEASE 免费且不重抽当前报价，必须先释放才能换保留对象。成功购买/替换消耗保留；购买失败、部署、升级选择、暂停和查看背包不会丢失。回标题、败北、胜利和新一局清除。未使用保留时，旧抽取/RNG、交易与战斗行为保持一致；使用保留时抽取三项是明确的选择后果。没有新道具、价格、战斗数值、图片或存档系统。

一、恢复新资源包
在完整 FPSgun 仓库目录运行（Python 3.8+）：
  python Deliveries/MossCircuit/restore_deliveries.py --version v28 --output restored-v28
只校验、不生成文件：
  python Deliveries/MossCircuit/restore_deliveries.py --version v28 --verify-only
帮助程序校验连续分块及完整文件的 SHA-256 / Git blob ID，在新的 restored-v28 目录生成 MossCircuit.pck 和本说明。它不联网、不解压、不运行游戏或自动安装，不覆盖已有文件。输出文件系统必须支持硬链接；否则明确失败。逐文件原子发布不是整批事务。Windows NTFS 未实际执行验证。

新 MossCircuit.pck：41,361,216 字节
SHA-256：5db5ded8a5b18eb6ac391b58a261e245588aa52cd7dbc65575f5101fb5828f69
14 个 Git 存储分块恢复为一个完整 PCK，不是差分补丁，也无需再合并 ZIP。不要把单个 chunk 当作 PCK。

二、原程序与首次安装
Linux MossCircuit.x86_64：71,075,864 字节，权限 0755
SHA-256：2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
Windows MossCircuit.exe：104,659,456 字节
SHA-256：91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6
现有 v19–v27 交付复用上述程序。首次安装先按 Deliveries/MossCircuit/README.md 恢复 v19 原始平台分卷，核对完整 ZIP 哈希并解压完整平台包，保留许可证，再替换新 PCK。只下载 v28 不能直接运行；不要使用未知版本的 EXE/ELF。

三、手动备份、替换和回退
1. 完全关闭游戏。核对程序与新 PCK 的上述哈希。
2. 将安装目录中的旧 MossCircuit.pck 备份到一个此前不存在的名称，例如 MossCircuit.pck.before-v28，确认备份哈希等于替换前旧文件。不要覆盖已有备份。
3. 只把 restored-v28/MossCircuit.pck 复制到程序旁，保持相邻。不要替换程序、许可证或其他文件，不要直接安装 chunks。
4. Linux 启动 ./MossCircuit.x86_64；Windows 启动 MossCircuit.exe。
5. 回退时关闭游戏，将新 PCK 移至另一个保留位置，再将已校验的旧备份恢复为 MossCircuit.pck；其他文件保持原样。
当前若确为 v27，旧 PCK 为 41,352,052 字节，SHA-256 dae99ca5e7b967a6cc7d6493f7a662cd8927f4009fd17049619983a846cfde89。其他版本必须使用该版本原始校验记录，不得冒称 v27。旧整包的 ARTIFACT_SHA256.json 只描述旧整包；新 PCK 身份以本说明及 CATALOG.json 为准。
Linux 校验：sha256sum MossCircuit.x86_64 MossCircuit.pck
Windows PowerShell 校验：Get-FileHash MossCircuit.exe,MossCircuit.pck -Algorithm SHA256
任何校验失败则停止替换，不跳过检查或运行未知程序。

四、操作与验证范围
WASD / 方向键移动，空格冲刺，Esc 暂停，I 查看构筑；菜单 Tab / Shift+Tab、Enter / Space。显示设置只在当前会话有效，不保存到磁盘。现有 ui_accept 默认键盘映射为 Enter/KP Enter/Space，没有 joypad A 绑定；合成 UI action 测试不代表实体手柄支持或认证，没有添加新手柄绑定。
独立源码验收包含首次冷导入、最终复用缓存再验证及 87 个独立入口（加导入共 88 项），输入哈希无变化；Python 安全检查 3 项、精确 PCK 资源检查 837 项及包内实际保留/交易检查 901 项通过。独立源码受控检查另覆盖 285 项数据/损坏记录防御和 3,170 项 UI 布局/回调/合成 action 检查；两模式 960/1280 实际窗口键鼠审查单独记录，不把受控状态当成普通取得。
单次普通 Rooms 流程使用种子 128、CUA 自动键鼠和战术暂停，不注入构筑/货币或程序化游戏状态。第一商店 66 scrap，免费保留第 2 格 Rail，购买 Power 18，再各花 5 刷新两次，剩 38 时 Rail 的 BUY42 禁用而 RELEASE 可用。自然清理第 2 房后进行 Light Feet 与 Magnet 升级，第二商店 73 scrap 仍保留原 Rail；实际 BUY42 后剩 31，Rail 装入 SLOT2，当前主伤害 34.50，原卡变 SOLD 并清除保留。有限验证到第二商店购买，不宣称完整战役、长期经济平衡或实体手柄验收。
本次原生日志保留 VSync 不支持切换及 ALSA ERR_CANT_OPEN 后 dummy 音频回退；不宣称零原生诊断或声音验收。关闭方式与运行前后文件哈希在独立证据中明确记录。
两平台预设 PCK 字节一致，程序没有重编译。Windows 只是既有程序 + 新 PCK，未在 Windows 执行。云端音频/显示驱动限制按本次原生日志如实记录，不宣称声音验收或普遍性能/平衡保证。完整有限证据见源码 docs/validation/independent-v28。
