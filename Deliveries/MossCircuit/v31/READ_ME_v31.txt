MossCircuit v31 — Starting loadouts / 起始构筑选择
GitHub 完整资源包更新，不是独立可执行程序；不发送聊天附件。

标题页可选择同一角色的三种起始装备：Rivet Starter 为 Rivet Gun +35 scrap（默认原路径），Scatter Starter 为 Scrap Shotgun +23，Rail Starter 为 Rail Lance +17。均为普通100 HP/基础移动速度、单武器、无模块、无永久升级；不是新角色、职业被动、解锁或存档系统。沿用已有图标与挂位，不增加新美术。

这是装备方式与初始流动废料的取舍：Rivet 射击准确频繁、余钱最多；Shotgun 近距离散射但射程短、间隔较长，不能保证所有弹丸命中；Rail 射程长且穿透，但余钱最少、间隔最长。当前武器目录购买价加初始废料均为59，只是本次调值依据，不证明强度相等。初始废料在数据中固定，商店价格变化不会自动重算；之后买卖、保留报价、升级兑换和武器排序仍遵循原规则，不额外退款或发奖励。

选项只在标题页修改，不消耗随机数。已拥有的不同起始标签会有意影响原有商店倾向，因此不能保证跨构筑同种子的报价相同。当前会话内切换模式、查看指南/设置或返回标题保留选择；重新启动程序默认 Rivet。完成/失败后的 SAME SEED 或 NEW SEED 重开使用本局最初的构筑身份，不是后来买卖/重排后的装备；STARTED WITH 标记来源而非仍拥有的物品。START 始终明确显示所选构筑和起始废料。

一、恢复完整资源包
在完整 FPSgun 本地仓库目录运行（Python 3.8+）：
  python Deliveries/MossCircuit/restore_deliveries.py --version v31 --output restored-v31
只校验、不写文件：
  python Deliveries/MossCircuit/restore_deliveries.py --version v31 --verify-only
工具校验有序连续分块和完整文件的 SHA-256 / Git blob ID，在新的 restored-v31 目录生成 MossCircuit.pck 和本说明。不联网、不解压、不执行游戏、不自动安装、不覆盖已有文件。输出文件系统须支持硬链接，否则明确失败。逐文件原子发布不是整批事务；Windows NTFS 未实际执行验证。

新 MossCircuit.pck：41,379,260 字节
SHA-256：ceba66d0091b2dfdcea3cb80c659fa252758b1c06e6bbb3b5f7d9edb3c99d37c
14 个 Git 存储分块恢复成一个完整 PCK，不是差分补丁，也无需再合并 ZIP。不要把单个 chunk 当作 PCK。

二、原程序与首次安装
Linux MossCircuit.x86_64：71,075,864 字节，权限 0755
SHA-256：2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
Windows MossCircuit.exe：104,659,456 字节
SHA-256：91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6
现有 v19–v30 交付复用上述程序。首次安装先按 Deliveries/MossCircuit/README.md 恢复 v19 原始平台分卷，核对完整 ZIP 哈希并解压完整平台包，保留许可证，再替换新 PCK。仅下载 v31 不能直接运行，不要使用未知版本的程序。

三、手动备份、替换和回退
1. 完全关闭游戏。核对程序和新 PCK 的上述哈希。
2. 把安装目录的旧 MossCircuit.pck 备份到此前不存在的名称，例如 MossCircuit.pck.before-v31；确认备份哈希等于替换前旧文件。不要覆盖已有备份。
3. 只把 restored-v31/MossCircuit.pck 复制到程序旁，保持相邻。不替换程序、许可证或其他文件，不直接安装 chunks。
4. Linux 启动 ./MossCircuit.x86_64；Windows 启动 MossCircuit.exe。
5. 回退时关闭游戏，将新 PCK 移到另一保留位置，再把已校验的旧备份恢复为 MossCircuit.pck；其他文件不变。
若当前确为 v30，旧 PCK 为 41,368,536 字节，SHA-256 c7485c5a423312fac0c064e5a5a2815cc36284f6018a020c9c54e64b6dcec894。其他版本须使用对应原始校验记录，不能冒称 v30。旧整包 ARTIFACT_SHA256.json 仅描述旧整包；新资源身份以本说明和 CATALOG.json 为准。
Linux 校验：sha256sum MossCircuit.x86_64 MossCircuit.pck
Windows PowerShell 校验：Get-FileHash MossCircuit.exe,MossCircuit.pck -Algorithm SHA256
校验失败就停止替换，不跳过检查或运行未知程序。

四、输入与有限验证
WASD / 方向键移动，空格冲刺，Esc 暂停，I 查看构筑；菜单 Tab / Shift+Tab、Enter / Space。三张起始卡均可在初始视口选择，下方 BASE 详情可滚动查看；START 保持初始焦点；选择按钮不是默认启动动作。默认 ui_accept 为键盘 Enter/KP Enter/Space，无新手柄绑定；合成 action 测试不代表实体手柄支持。设置和起始选择均不保存到磁盘。
作者与独立最终回归均为96个独立脚本+导入，共97项，通过且622个冻结输入无变化。最初真正冷导入与最终复用缓存的再验证分开记录。Python安全检查3项通过；独立从源码导入资源生成的指纹与构建一致，实际PCK资源843项（61精确文件、58图像、25动作/281帧），以及PCK内独立构筑977项/界面544项通过。默认旧状态投影的24案例与36项时序结果逐字节等于已验收v30，不声称新增元数据整对象相同。
受控源码窗口在Arena/Rooms的960×540与1280×720检查三种选项初屏可见、键盘/鼠标选择、固定START、种子跨指南/设置/模式保留和来源标签；受控装备改变/结果状态后，通过实际Retry/New Seed恢复起始身份。独立美术检查13张指定静态图，沿用资源身份不变。这是受控设置与有限操作，不代替普通游玩。两类真实候选问题（失效标题回调访问已释放控件、初屏隐藏所有选择）已修正，原失败及单独测试断言修正均保留。
实际Linux相邻PCK普通输入验证（自动化CUA键鼠与战术暂停，无程序注入状态）：新进程默认Rivet；Arena种子128选择Scatter，初始23 scrap/100 HP/Shotgun；Rooms种子128选择Rail，初始17/100 HP/Rail，来源标签均正确。Scatter自然推进到LV2并选择升级兑换；后续41 scrap包含正常拾取，不能当作隔离的+10证明。Rail自然到达48 scrap首店，先后在两个可见选项页点击Light Feet；HUD为LV2，不能推断两次升级等级。无购买；随后部署Room2只观察暂停/返回标题。短促键盘暂停/物品栏尝试未逐一得到可见确认，明确的界面按钮导航成功，原尝试保留。不是完整战役或各起始构筑平衡验收。
两次普通路线都观测到返回标题；最终使用启动终端Ctrl+C关闭，确认游戏窗口消失，不称作游戏内优雅退出。关闭后622输入、ELF/PCK哈希不变。原生环境仍有不支持的VSync与ALSA打开失败后dummy音频回退；无新增SCRIPT ERROR，不宣称音频验收。
两平台预设 PCK 字节一致，程序未重编译。Windows 是既有程序 + 新 PCK，未在 Windows 运行。完整有限证据见源码 docs/validation/independent-v31；不宣称完整战役、长期平衡、普遍性能、实体手柄或音频验收。
