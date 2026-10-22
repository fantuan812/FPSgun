# Godot 像素资产管线 v0.1

## 生产约定

- 原始动作使用内置 image_gen，一张动作图含 3×3、按行顺序的九帧；透明背景、同视角、同人物身份、同朝向、足够留白。
- 本轮角色原图主角 1254×1254，甲虫 1268×1241，生成器没有严格遵守3等分尺寸。不能把请求尺寸当实际尺寸。
- `art_source/alpha_bounds.json` 是对实际PNG alpha>128包围盒的只读测量。生成图片每行脚底偏移明显，直接均分会跳动。因此 `art.gd` 用每格包围盒作为 AtlasTexture.region，以 margin 补齐为统一画布，水平居中、脚底固定为画布底部上20源像素。没有修改PNG像素。
- 9帧保留腿姿态变化；固定脚底降低生成图跨行布局抖动，但没有真人窗口观察时不能保证动画已经完美。当前只做左右镜像，不是八方向动画。
- idle复用帧0。不要用重新生成角色立绘代替walk相邻动作。下一动作单独一张九帧sheet，仍需逐帧审阅。
- Source PNG为高分辨率像素风生成图，不是人工逐像素32×32画稿；最近邻显示提升像素观感，未宣称严格低色数或整数像素网格。

## Godot 消费

- AnimatedSprite2D + SpriteFrames，walk=9帧，idle=1帧。
- AtlasTexture.filter_clip=true；CanvasItem.TEXTURE_FILTER_NEAREST；import lossless，mipmaps=false（默认导入文件中可核）。
- 使用Godot区域切片，不做破坏性拆图。frames缓存键包括资源路径和fps，避免不同敌人频率误用首个缓存。
- `project.godot` 960×540固定viewport缩放；窗口默认1280×720。
- 接缝：地块每块全是地面，无高度墙体，任意排序不会影响可行走性。原图边缘没有做到逐像素完全一致，所以地图采用可见统一格砖接缝；不是自动地形terrain无缝保证。要做自然地形，后续需单独制作Wang/terrain边角组合并实测匹配。

## 来源与使用边界

本轮三PNG均在2026-10-22由本任务内置image_gen生成，原始文件被复制至assets，未获取第三方游戏解包资源。提示词与hash见 `art_source/provenance.json`。代码为本任务新写；Godot引擎未随包附带。AI生成不保证任何法域的排他性权利，商业发布前仍应人工审查资产相似性与所用平台条款。

官方参考（实现采用Godot4.6.3，页面会滚动）：
- https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
- https://docs.godotengine.org/en/stable/classes/class_atlastexture.html
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html
