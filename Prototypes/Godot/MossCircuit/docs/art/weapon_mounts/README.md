# v8 分层角色与世界武器素材

## 修正原因及覆盖

v7 hero_attack 九帧把同一把小手枪和火花画进身体，无法如实表现换武器。v8 用 image_gen 编辑为 clean_hero_attack：每帧空手，去掉枪、枪口火光、烟雾及弹壳；身体身份和抬手/发力/恢复序列保留。武器和开火特效由运行时独立层表现，角色不负责画固定枪火。

本轮已重新逐张实看 hero_walk、hero_attack、hero_hurt、hero_death、hero_dash；idle 在 scripts/art.gd 中复用 walk 第0帧。只有旧 attack 有烘焙枪；walk/idle/hurt/death/dash 原本空手，保留不重画。不声称重新生成了六组动作。v7 文件完全不改；v8运行应采用 hero_modular_manifest 覆盖旧攻击来源。

## 真正世界武器，不是库存图标

最终采用六件独立 PNG（不是库存图标），world_weapon_manifest schema_version=2 分别加载：铆钉枪 rivet_gun、双管霰弹枪 scrap_shotgun、双轨轨道枪 rail_lance、面向镜头的齿锯 orbit_saw、三弧刃回旋盘 return_disc、粗短炮管 shock_mortar。没有角色、手掌、UI卡片/边框和烘焙枪火。早期 world_weapons_atlas.png 有环境光晕，仅留作来源记录，运行 manifest 不再加载。六单图与旧atlas保持武器类别但统一为更简化的硬像素轮廓。

manifest 的 region 为源atlas像素矩形；grip/muzzle/projectile_anchor 是该矩形内归一化坐标。四把枪朝右，握持点在把手/后机身、muzzle在管口；锯与盘以轮毂中心作握点/弹体中心。visible_length 是建议世界像素尺寸，24–42范围。运行时需按武器类型旋转/挂载，不要把迫击炮当直射枪或把回旋盘当永远握持的枪。

角色攻击每帧grip根据空手手套中心视觉测量，统一418×340窗口、固定foot anchor、统一reference_height。禁止按每帧alpha_bbox重新居中缩放。身体保留原始0..8顺序，release_frame=3；独立槽的瞄准、后坐、四槽偏移、弹体与回收逻辑由主程实现。所有手掌挂点是可调的作者测量值，并非经窗口实机精密校准的承诺。

## 原图与验证

PNG都是内置image_gen生成的原始输出，未用Python修改、抠图或重绘。prompts.json保留原始Prompt、修订Prompt和来源路径；两个manifest提供SHA256。build_manifests.py只读取像素产生元数据；validate_assets.py只读验证区域、透明、>=8px安全边距、归一化坐标、9帧互异和SHA256。验证通过不等于GUI或Windows试玩通过。

## 光晕返修结果与保留边界

早期六件atlas及两次返修仍有明显外围金灰光晕，未通过cutout视觉验收，保留原文件及cutout_review.json作为失败记录，不再由运行manifest加载。root实看单锯片候选改善后，授权其余五件各一次独立生成，最终六件全为独立PNG。逐图实看均未见旧atlas那样的大范围环境晕，像素轮廓与绿/铁灰/暗金配色统一，但保留少量低alpha边缘及孤立微弱像素，不宣称每个轮廓外像素绝对为零。

individual_weapon_prompts.json记录最终六图Prompt与来源。所有原PNG未做Python图像编辑。元数据按各图真实尺寸重测握点、管口、中心与reference_width；回旋盘1254×1254，其他1774×887，region取完整单图。建议world像素长度统一按reference_width缩放，避免透明留白造成物体过小。具体手掌/枪口在窗口中仍需校准。

运行时可选择仅世界武器的alpha-cutoff材质以去除残余低alpha像素，不应影响角色或VFX；会硬化边缘、可能丢失微弱细节，尚未GUI验收，不把源图检查等同游戏合成截图。高分辨率像素风未保证严格统一32px网格。


独立检查仍需覆盖：每种武器实际装配可辨识、四槽各自跟随和瞄准、移除武器后无残留固定枪、枪口VFX取muzzle、盘/锯/炮的表现型，以及暂停/死亡/重置清理。不以静态图集预览冒充运行截图。
