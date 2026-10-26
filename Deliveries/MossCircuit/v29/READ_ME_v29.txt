MossCircuit v29 — Salvage one stat choice / 放弃一次属性选择换废料
GitHub 完整资源包更新，不是独立可执行程序；不发送聊天附件。

每张升级页仍从原有六种永久属性中抽取三个选项，另提供可选的 SALVAGE THIS UPGRADE：放弃本次属性选择，立即获得固定 10 scrap，已获得的等级和经验不变。废料只能在之后按原模式政策正常到达的商店花费；不会额外开启或保证商店。可以用它补足已保留报价的预算，但不会自动购买、打折或退款。不是第七种升级、免费重抽、新道具或自动代选。10 是实验性调值，不是整体经济平衡结论。

每次选择只能结算一次，旧页面/重复回调不会给下一页发钱。奖励不受废料加成影响，原有小数余量保持不变，不回等级、不治疗、不重算装备或重置在途攻击。下一张已排队升级页或正常商店仍按旧流程抽取；“兑换本身不抽 RNG”不等于后续合法页面不抽取。未使用新选项时，40 项两模式旧升级/队列/保留报价/商店状态与 RNG 轨迹保持字节一致。原有 37 项装备目录、六种属性、价格、遭遇与素材不变。

一、恢复完整资源包
在完整 FPSgun 本地仓库目录运行（Python 3.8+）：
  python Deliveries/MossCircuit/restore_deliveries.py --version v29 --output restored-v29
只校验、不写文件：
  python Deliveries/MossCircuit/restore_deliveries.py --version v29 --verify-only
工具校验有序连续分块和完整文件的 SHA-256 / Git blob ID，在新的 restored-v29 目录生成 MossCircuit.pck 和本说明。不联网、不解压、不执行游戏、不自动安装、不覆盖已有文件。输出文件系统须支持硬链接，否则明确失败。逐文件原子发布不是整批事务；Windows NTFS 未实际执行验证。

新 MossCircuit.pck：41,363,792 字节
SHA-256：77d6b41df3cea5036f99608a837983767f31c2e680c2622c1a83654adf2e6cfc
14 个 Git 存储分块恢复成一个完整 PCK，不是差分补丁，也无需再合并 ZIP。不要把单个 chunk 当作 PCK。

二、原程序与首次安装
Linux MossCircuit.x86_64：71,075,864 字节，权限 0755
SHA-256：2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0
Windows MossCircuit.exe：104,659,456 字节
SHA-256：91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6
现有 v19–v28 交付复用上述程序。首次安装先按 Deliveries/MossCircuit/README.md 恢复 v19 原始平台分卷，核对完整 ZIP 哈希并解压完整平台包，保留许可证，再替换新 PCK。仅下载 v29 不能直接运行，不要使用未知版本的程序。

三、手动备份、替换和回退
1. 完全关闭游戏。核对程序和新 PCK 的上述哈希。
2. 把安装目录的旧 MossCircuit.pck 备份到此前不存在的名称，例如 MossCircuit.pck.before-v29；确认备份哈希等于替换前旧文件。不要覆盖已有备份。
3. 只把 restored-v29/MossCircuit.pck 复制到程序旁，保持相邻。不替换程序、许可证或其他文件，不直接安装 chunks。
4. Linux 启动 ./MossCircuit.x86_64；Windows 启动 MossCircuit.exe。
5. 回退时关闭游戏，将新 PCK 移到另一保留位置，再把已校验的旧备份恢复为 MossCircuit.pck；其他文件不变。
若当前确为 v28，旧 PCK 为 41,361,216 字节，SHA-256 5db5ded8a5b18eb6ac391b58a261e245588aa52cd7dbc65575f5101fb5828f69。其他版本须使用对应原始校验记录，不能冒称 v28。旧整包 ARTIFACT_SHA256.json 仅描述旧整包；新资源身份以本说明和 CATALOG.json 为准。
Linux 校验：sha256sum MossCircuit.x86_64 MossCircuit.pck
Windows PowerShell 校验：Get-FileHash MossCircuit.exe,MossCircuit.pck -Algorithm SHA256
校验失败就停止替换，不跳过检查或运行未知程序。

四、输入与有限验证
WASD / 方向键移动，空格冲刺，Esc 暂停，I 查看构筑；菜单 Tab / Shift+Tab、Enter / Space。新选项不默认聚焦，仍先聚焦普通 SELECT。默认 ui_accept 只有 Enter/KP Enter/Space 键盘映射，没有 joypad A 绑定；合成 action 测试不代表实体手柄支持，没有添加新绑定。显示设置仅当前会话有效，不保存到磁盘。
独立源码有首次真实冷导入，最终同源码复用缓存再验证：90 个独立入口加导入共 91 项引擎运行均退出 0、无引擎错误，601 个源码输入不变。独立包装器最初把 18 项测试的旧成功摘要误判为失败；保留原始结果后按既有成功格式逐项复核，未重跑或改写游戏来掩盖失败。Python 安全检查 3 项、独立精确 PCK 资源 837 项、包内实际兑换机制 294 项和 UI 901 项通过。受控两模式 960/1280 实际窗口另验证默认 SELECT、Tab/Space、鼠标、队列与保留报价支付；受控状态不称为普通获得。
单次普通 Rooms 种子 128 使用 CUA 自动键鼠和战术暂停，不注入构筑、货币或程序化游戏状态。实际完成第一遭遇后，第一张已获得选择页显示 66 scrap；Tab 三次后 Space 兑换，下一张已排队选择页显示 76。默认 Return 再选择 Repair Plating，正常第一商店仍为 76，Rivet 主伤害 15、全局伤害加成 0%，HP/上限 120。该健康结果来自随后正常选择的 Repair Plating，不归因于兑换。未购买、未要求完整通关或额外两店流程。
本次原生日志仅有既有 VSync 不支持切换，以及 ALSA ERR_CANT_OPEN 后 dummy 音频回退；没有新增脚本错误，不宣称零原生诊断或音频验收。结束后从启动终端 Ctrl+C 关闭，确认窗口消失，程序/PCK 前后哈希不变；不称为游戏内优雅退出。
两平台预设 PCK 字节一致，程序未重编译。Windows 是既有程序 + 新 PCK，未在 Windows 运行。完整有限证据见源码 docs/validation/independent-v29；不宣称完整战役、长期平衡、普遍性能、实体手柄或音频验收。
