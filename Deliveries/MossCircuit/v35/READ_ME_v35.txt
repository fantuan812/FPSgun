MossCircuit v35 / Player HP-loss and Mirror Shell sound feedback
LOCAL VERIFIED SOURCE/PACK — PUBLICATION IS A SEPARATE GATE

状态
这是本地已核验的完整 v35 资源包；v32–v35 尚未宣称 GitHub 发布，已接受远端仍为 v31。本地路径、私有恢复点或计算的 Git blob ID 不是远端可达性证明。

变化与边界
增加两种原创确定性非语音短音效：实际 HP 减少与真正 Mirror Shell 挡击。不是武器/敌人/音乐系统。PRESENTATION SETTINGS 中的 MUTE PLAYER FEEDBACK SOUNDS 仅当前进程保留；静音不回放旧事件，降低闪光独立。音频不可用不影响伤害、经济、AI、随机数或游戏时间。实际输出设备名称只作状态提示，Dummy 明确没有物理输出。数字波形/混音证据不是听感、安全音量或扬声器证明。

前提与恢复
这是完整 PCK，不是独立程序、ZIP 或差分补丁。首次安装仍须按 v19 说明恢复已有完整平台包及许可证；需要原有核验一致的程序，不提供新 EXE。
在包含分块的 FPSgun 检出根目录运行：
  python Deliveries/MossCircuit/restore_deliveries.py --version v35 --verify-only
  python Deliveries/MossCircuit/restore_deliveries.py --version v35 --output recovered-v35
Windows 可用 py -3。要求 Python 3.8+ 与支持硬链接的文件系统（如 NTFS）。助手不联网、不解压、不安装、不执行；检查逐块及整包 SHA-256/Git blob ID，逐文件原子发布并拒绝覆盖。原子性不是整个版本批次事务。不要安装单块。

手动更新与回退
1. 关闭游戏，核验现有程序身份。
2. 将实际旧 MossCircuit.pck 复制到独立且不存在的备份名；记录 SHA-256 并确认备份一致，不覆盖旧备份。
3. 核验 recovered-v35/MossCircuit.pck 的下列身份，再复制到程序旁，保持文件名 MossCircuit.pck。
4. 从程序原目录正常启动。正式程序禁用 --main-pack 路径覆盖，不要用该参数启动普通游戏。
5. 回退前关闭游戏，把自己的已核验旧备份复制回 MossCircuit.pck，重新核验。历史哈希不能代替实际备份。
独立文件回退凭据覆盖本地 v34→v35→v34，与未变化 ELF 同目录；只是实际文件操作，不是旧版运行、Windows 或 Git 下载证明。

精确身份
MossCircuit.pck: 41,438,836 bytes
SHA-256: 99b5232f7d5866ab3152f78990ed6ad37ed55957cf85f1712418c056daa3638d
Linux/Windows 两预设 PCK 字节相同。
已有 MossCircuit.x86_64: 71,075,864 bytes
SHA-256: 2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
已有 Windows EXE 历史 SHA-256: 91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6（本次未执行）
历史本地 v34 PCK: 250ea5966ff7ca35b42a13cd813ba5ff156288cfc97110a411dd73664ccbbe02

验证摘要
作者最终 696 输入完整回归 119 脚本+导入=120/120 通过；独立逐条审计全部原始记录、106 次条件 teardown 与哈希，不冒称独立重跑完整 120。独立实际执行最终 PCK：通用资源853、音频权限773、混音236、视图168、结算类型960；Python PCM38、安全3。通用资源指纹不含 WAV PCM，加载后 PCM 身份由专用权限检查验证。先前 109/113 与 116/119 仍为失败，首次无效 mixer 测试也保留；修复仅最终测试释放 seam 的条件观察，不放宽预算或日志错误门禁。共享 helper 的15个谓词检查（1正例、14负例）是确定性测试，不是实际资源滞留注入。
受控原生两模式两尺寸共11张原图：7次已结算请求、6次接受、1次静音拒绝；真实失焦暂停已见，但此前音效已自然结束，不能称失焦截断活动音。外部夹具 F9 退出0，不是游戏自带退出功能。
一次正式 ELF 普通 Arena/Rivet/seed240102 路线，无注入/重置/重试，经过自然结算和升级到首次商店（164废料），保留10张原图。未建立普通 HP 减少、自然 Mirror 获取/挡击或普通音频输出证据，也未完成战役。最早错误 --main-pack 启动在游戏出现前退出1，记录保留；随后正常 sidecar 启动及外部关闭退出0。
全部音频捕获使用 Dummy 内部混音，没有物理听音、Windows、整体平衡或性能结论。原生 VSync 不支持警告保留，无 GDScript/资源退出错误。恢复助手十项及文件回退的最终执行状态见独立交付凭据，不能用本说明代替凭据。
