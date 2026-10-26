MossCircuit v30 — Weapon order / 商店武器排序
GitHub 完整资源包更新，不是独立可执行程序；不发送聊天附件。

商店中已拥有的武器卡新增 MOVE EARLIER / MOVE LATER：免费与相邻副本换位，原有剩余冷却、瞄准和后坐表现年龄跟随各自副本。SLOT 1 使用原手持挂位，其他槽使用原侧挂几何。重复同类武器仍是不同槽位副本；换位不会重置或同步攻击时钟，不花钱也不发钱，不改属性、标签加成、装备目录或 RNG。旧页面和重复操作不会移动后来显示的另一份副本。

同一 tick 已就绪的武器按槽位处理，但弹丸旅行和延迟爆炸仍遵守原规则，不能笼统宣称“靠前一定先命中”或伤害更高。例如持有 Fracture Coil、冷凝与旋锯均已就绪且目标在两者范围内并存活时，冷凝先于旋锯可消费本 tick 新标记，反序可保留标记并在下一次对齐且标记尚未过期的循环消费后重新施加；这是时序/慢速保留取舍，不保证持续 DPS 提升。换位只在商店执行；普通背包/战斗/暂停不可编辑。若仍有玩家弹丸或待爆榴弹，按钮禁用，动作拒绝而不清除、重定向或重绑在途攻击。正常遭遇结算仍按旧规则清理后进入商店。

一、恢复完整资源包
在完整 FPSgun 本地仓库目录运行（Python 3.8+）：
  python Deliveries/MossCircuit/restore_deliveries.py --version v30 --output restored-v30
只校验、不写文件：
  python Deliveries/MossCircuit/restore_deliveries.py --version v30 --verify-only
工具校验有序连续分块和完整文件的 SHA-256 / Git blob ID，在新的 restored-v30 目录生成 MossCircuit.pck 和本说明。不联网、不解压、不执行游戏、不自动安装、不覆盖已有文件。输出文件系统须支持硬链接，否则明确失败。逐文件原子发布不是整批事务；Windows NTFS 未实际执行验证。

新 MossCircuit.pck：41,368,536 字节
SHA-256：c7485c5a423312fac0c064e5a5a2815cc36284f6018a020c9c54e64b6dcec894
14 个 Git 存储分块恢复成一个完整 PCK，不是差分补丁，也无需再合并 ZIP。不要把单个 chunk 当作 PCK。

二、原程序与首次安装
Linux MossCircuit.x86_64：71,075,864 字节，权限 0755
SHA-256：2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
Windows MossCircuit.exe：104,659,456 字节
SHA-256：91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6
现有 v19–v29 交付复用上述程序。首次安装先按 Deliveries/MossCircuit/README.md 恢复 v19 原始平台分卷，核对完整 ZIP 哈希并解压完整平台包，保留许可证，再替换新 PCK。仅下载 v30 不能直接运行，不要使用未知版本的程序。

三、手动备份、替换和回退
1. 完全关闭游戏。核对程序和新 PCK 的上述哈希。
2. 把安装目录的旧 MossCircuit.pck 备份到此前不存在的名称，例如 MossCircuit.pck.before-v30；确认备份哈希等于替换前旧文件。不要覆盖已有备份。
3. 只把 restored-v30/MossCircuit.pck 复制到程序旁，保持相邻。不替换程序、许可证或其他文件，不直接安装 chunks。
4. Linux 启动 ./MossCircuit.x86_64；Windows 启动 MossCircuit.exe。
5. 回退时关闭游戏，将新 PCK 移到另一保留位置，再把已校验的旧备份恢复为 MossCircuit.pck；其他文件不变。
若当前确为 v29，旧 PCK 为 41,363,792 字节，SHA-256 77d6b41df3cea5036f99608a837983767f31c2e680c2622c1a83654adf2e6cfc。其他版本须使用对应原始校验记录，不能冒称 v29。旧整包 ARTIFACT_SHA256.json 仅描述旧整包；新资源身份以本说明和 CATALOG.json 为准。
Linux 校验：sha256sum MossCircuit.x86_64 MossCircuit.pck
Windows PowerShell 校验：Get-FileHash MossCircuit.exe,MossCircuit.pck -Algorithm SHA256
校验失败就停止替换，不跳过检查或运行未知程序。

四、输入与有限验证
WASD / 方向键移动，空格冲刺，Esc 暂停，I 查看构筑；菜单 Tab / Shift+Tab、Enter / Space。换位不是默认激活项；原购买/替换等焦点保持。默认 ui_accept 只有 Enter/KP Enter/Space 键盘映射，没有 joypad A 绑定；合成 action 测试不代表实体手柄支持，没有添加新绑定。显示设置仅当前会话有效，不保存到磁盘。
独立源码有首次真实冷导入，最终同源码复用缓存再验证：93 个独立入口加导入共 94 项通过，611 个源码输入保持不变。Python 安全检查 3 项、独立精确 PCK 资源 839 项、包内实际排序权威 837 项和 UI 512 项通过。24 项未使用排序的状态/RNG轨迹以及 36 项实际先后命中检查与 v29 字节一致；不把有意改变后的槽位输出要求为未换位输出。
受控两模式 960×540 / 1280×720 实际窗口另验证鼠标/键盘换位、重复副本、默认焦点、在途禁用、替换可达、只读背包及两朝向手持挂位。受控状态不称为普通获得。一个早期 UI 测试把 BUY 分组放到 REPLACE 前而误认首报价，保留原始失败后只修正测试的文档顺序选择；没有为此改动游戏。
单次普通 Rooms 种子 128 使用 CUA 自动键鼠与战术暂停，不注入构筑、货币或程序化游戏状态。自然完成第一房后选择 Overcharge 和 Repair Plating，第一商店 66 scrap → 购买 Rail42 → 24；对 Rivet 点击 MOVE LATER 后，Rail 为 SLOT1、Rivet 为 SLOT2，仍为 24。随后部署 Room2，观察实际战斗/挂位，再暂停查看只读背包，顺序保持。37.5 的 Rail 读数与 120 HP 来自所选属性，不是排序增伤或治疗；不要求完整通关。
本次原生日志仅有既有 VSync 不支持切换，以及 ALSA ERR_CANT_OPEN 后 dummy 音频回退；没有新增脚本错误，不宣称零原生诊断或音频验收。结束后从启动终端 Ctrl+C 关闭，确认窗口消失，程序/PCK 前后哈希不变；不称为游戏内优雅退出。
两平台预设 PCK 字节一致，程序未重编译。Windows 是既有程序 + 新 PCK，未在 Windows 运行。完整有限证据见源码 docs/validation/independent-v30；不宣称完整战役、长期平衡、普遍性能、实体手柄或音频验收。
