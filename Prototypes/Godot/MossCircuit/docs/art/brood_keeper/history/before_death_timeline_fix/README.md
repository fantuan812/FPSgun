# Broodkeeper 动作修订：16 / 9 / 16

用户澄清九帧仅为AI生成方便，并非动作上限。本版按动作节拍重生summon与death各16真实源姿态（单张4×4），保留短hurt原9帧/.27秒。不是复制九帧、补重复尾帧或仅减速播放。旧九帧候选保留在moss-art-v12，不覆盖历史；其summon/death已superseded，不是此版运行图。程序应把该历史单独归档，不把旧PASS当本次41帧证据。

## 素材与动作

源角色为v11原创brood_keeper，左向、苔绿四足壳体、奶白双孔脸、金足和五孔金环蜂巢。新summon首稿；新death首稿因横向留白紧，使用image_gen定向增加留白一次，最终PNG是该工具原始字节；hurt原字节复用。没有代码/Python绘制、缩放、修图或复制帧。完整提示/生成来源见prompts.json，SHA见manifest及producer-hashes.json。

summon 0中性，1–3撑足压壳，4–6蜂巢蓄动加强，7首次挺身发力代表**召唤尝试**，8–11回收下沉，12–15再次回稳到中性。warning .65秒对应0–6，attempt同tick进入7，recover .7秒对应7–15。图中无孩子、卵弹、生成物、光柱等外部特效，满cap产0只仍语义正确。帧6→7压缩到伸腿发力是主节拍，11→12有一次较明显回稳抬身；生成式序列并非手工逐像素匀速补间。

death 0中性，1–3失力，4–7折足下沉，8–11伏低，12–15最终沉降与余震，.72秒；不复活、不爆炸、不消散。末段是低姿新生成过渡，不是人为复制hold。蜂巢孔口受苔边/倾角部分遮挡，整体五孔身份延续。部分细节与高度有轻微生成漂移（如death3→4短暂抬高14源像素），不宣称严格骨骼/像素锁定。

## 安全裁片和透明padding（不是修图）

新两图均1254×1254。生成4×4的纵行距不规则，直接等分或硬套统一源矩形会污染邻行；采用程序确认的标准AtlasTexture.margin表达。每frame `region=[x,y,w,h]` 为**源图绝对裁片**；`margin=[left,top,total_extra_width,total_extra_height]` 为Godot Rect2语义。逻辑canvas=region.size+margin.size；`alpha_bbox=[x,y,w,h]`为**加上margin.position之后的逻辑canvas坐标**，不能重复加padding。

两张16帧图逻辑canvas全部313×360，anchor=[.5,330/360]；每整行共享源y/h与padding，不按逐帧bbox重新居中或缩放。各列源x固定[10,323,636,941]。summon行[y,h,padTop]为[100,275,76]/[380,298,47]/[670,280,66]/[950,275,83]；death为[130,260,93]/[480,255,100]/[825,215,134]/[1090,164,191]。margin=[0,padTop,0,360-h]，全为非负整数且top<=extraHeight。

例：death0 region=[10,130,313,260]、margin=[0,93,0,100]；源有效bbox绝对[48,161,274,367]，逻辑alpha_bbox=[38,124,226,206]，接地330。death0/1均330，所有clip frame0中性接地330。hurt维持418×360旧画布和旧元数据，无margin也兼容。

每clip固定reference_height取中性首帧：summon225、hurt269、death206。运行旧walk世界站高/reference_height作为**整clip固定scale**；不可按每帧bbox、伏地高度或源整格大小归一。summon发力帧7身高261（中性225），宽238（中性234），差异为伸腿/蜂巢挺身而非整机放大。无有意跳跃；最大源像素脚底误差summon6/death6/hurt7，已披露，不声称严格锁脚。

## QA与边界

`python docs/art/brood_keeper/validate_assets.py`只读PNG、生成JSON，可独立运行，无外部工作目录依赖。验证41非空唯一源帧；RGBA；新图源alpha>8安全边距summon>=13、death>=14；**全源有效alpha像素总数等于全部裁片有效alpha像素之和**，证明没有遗漏有效实体，也没有重复选入邻行实体；每个裁片边缘有透明安全带。每clip统一逻辑canvas、非负padding适配、首帧/死亡0–1接地、原hurt字节SHA均断言。validation.json记录逻辑接地/高度/逐帧SHA。

已实看完整两张16姿态及9帧hurt；无大面积低alpha光晕，但存在细边抗锯齿与渐变。**本批仍是高分辨率卡通sprite/像素风参考感，并非原生低分辨率pixel art，nearest不会改变素材本质。** 单动作单图，故无跨图接续；行3→4等跨行姿态已看，不以哈希互异替代动画质量声明。运行GUI和发布不在本美术验收范围，不能把源图QA说成窗口验收。旧v11冻结未改。
