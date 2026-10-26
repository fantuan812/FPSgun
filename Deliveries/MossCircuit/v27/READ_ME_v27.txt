MossCircuit v27 — Broodkeeper hollow pulse / 空心脉冲
GitHub 完整资源包更新，不是独立可执行程序；不发送聊天附件。

现有 Broodkeeper 先施放空心脉冲，再使用旧召唤，交替进行。脉冲在开始预警后固定中心，1 秒后仅对当前位于 70–180 像素环带内的玩家尝试一次原有 11 点伤害。两条橙边均危险；可进入内圈或移到外圈之外，但其他敌人仍能攻击。既有冲刺/受伤免疫规则不变，范围脉冲不会触发 Feedback Diode。没有新敌人/道具/波次池或 RNG 抽取；隔次召唤是明确的遭遇节奏变化。复用既有蓄力动作，不宣称新绘制动画。

一、恢复新资源包
在完整 FPSgun 仓库目录运行（Python 3.8+）：
  python Deliveries/MossCircuit/restore_deliveries.py --version v27 --output restored-v27
只校验、不生成文件：
  python Deliveries/MossCircuit/restore_deliveries.py --version v27 --verify-only
帮助程序校验连续分块及完整文件的 SHA-256 / Git blob ID，在新的 restored-v27 目录生成 MossCircuit.pck 和本说明。它不联网、不解压、不运行游戏或自动安装，不覆盖已有文件。输出文件系统必须支持硬链接；否则明确失败。逐文件原子发布不是整批事务。Windows NTFS 未实际执行验证。

新 MossCircuit.pck：41,352,052 字节
SHA-256：dae99ca5e7b967a6cc7d6493f7a662cd8927f4009fd17049619983a846cfde89
14 个 Git 存储分块恢复为一个完整 PCK，不是差分补丁，也无需再合并 ZIP。不要把单个 chunk 当作 PCK。

二、原程序与首次安装
Linux MossCircuit.x86_64：71,075,864 字节，权限 0755
SHA-256：2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
Windows MossCircuit.exe：104,659,456 字节
SHA-256：91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6
现有 v19–v26 交付复用上述程序。首次安装先按 Deliveries/MossCircuit/README.md 恢复 v19 原始平台分卷，核对完整 ZIP 哈希并解压完整平台包，保留许可证，再替换新 PCK。只下载 v27 不能直接运行；不要使用未知版本的 EXE/ELF。

三、手动备份、替换和回退
1. 完全关闭游戏。核对程序与新 PCK 的上述哈希。
2. 将安装目录中的旧 MossCircuit.pck 备份到一个此前不存在的名称，例如 MossCircuit.pck.before-v27，确认备份哈希等于替换前旧文件。不要覆盖已有备份。
3. 只把 restored-v27/MossCircuit.pck 复制到程序旁，保持相邻。不要替换程序、许可证或其他文件，不要直接安装 chunks。
4. Linux 启动 ./MossCircuit.x86_64；Windows 启动 MossCircuit.exe。
5. 回退时关闭游戏，将新 PCK 移至另一个保留位置，再将已校验的旧备份恢复为 MossCircuit.pck；其他文件保持原样。
当前若确为 v26，旧 PCK 为 41,347,432 字节，SHA-256 59096e791e270250a7c6a314d741d7295100016863be2ba85455795c88017e33。其他版本必须使用该版本原始校验记录，不得冒称 v26。旧整包的 ARTIFACT_SHA256.json 只描述旧整包；新 PCK 身份以本说明及 CATALOG.json 为准。
Linux 校验：sha256sum MossCircuit.x86_64 MossCircuit.pck
Windows PowerShell 校验：Get-FileHash MossCircuit.exe,MossCircuit.pck -Algorithm SHA256
任何校验失败则停止替换，不跳过检查或运行未知程序。

四、操作与验证范围
WASD / 方向键移动，空格冲刺，Esc 暂停，I 查看构筑。显示设置只在当前会话有效，不保存到磁盘。
独立源码验收包含首次冷导入、最终复用缓存再验证和 83 个独立入口，输入哈希无变化；Python 安全检查 3 项、精确 PCK 检查 835 项通过。受控实际机制检查 948 项、数据验证 45 项，以及两模式 960/1280 窗口的环带/空洞/位移/重叠/动作审查分别记录，不从截图推断精确伤害。
有限普通操作使用种子 2701、Rooms 模式，以 CUA 自动键鼠和战术暂停完成一次正常流程，不注入构筑/货币或程序化游戏状态。第 3 房观察到 Broodkeeper 的第一次空心预警，随后玩家在环外保持 140/140 HP；敌人被初始 Rivet 击杀，未清晰捕获第二次召唤。直接观察 CIRCUIT COMPLETE，Room 3/3、LV 4、11 kills、1 Rivet/0 modules。该单次流程不证明普通操作中的 11 点伤害归因或完整交替周期；相关精确语义由受控和包内测试证明，不作长期平衡结论。
两平台预设 PCK 字节一致，程序没有重编译。Windows 只是既有程序 + 新 PCK，未在 Windows 执行。云端 VSync 不支持切换，ALSA 打开音频失败后回退 dummy 驱动；不宣称零原生诊断或声音验收。本次返回标题后由外部终端 Ctrl+C 关闭，不称为游戏内优雅退出；关闭后程序和资源包哈希未变。完整有限证据见源码 docs/validation/independent-v27。
