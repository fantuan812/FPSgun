import bpy,pathlib
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
c=bpy.data.collections.get('Reactor_Core')
if c:
 for o in list(c.objects):bpy.data.objects.remove(o,do_unlink=True)
 bpy.data.collections.remove(c)
with bpy.data.libraries.load(str(R/'reactor/reactor.blend'),link=False) as (a,b):b.collections=['Reactor_Core']
bpy.context.scene.collection.children.link(b.collections[0])
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
print('REACTOR_REFRESHED')
from mathutils import Vector
import math
import json
CFG=json.loads((R/'core_config.json').read_text())
for n,conf in CFG['cameras'].items():
 o=bpy.data.objects[n];o.location=conf['position'];o.rotation_euler=(Vector(conf['target'])-o.location).to_track_quat('-Z','Y').to_euler();o.data.lens=conf['lens_mm']
bpy.data.objects['Rear zone'].rotation_euler=(math.pi/2,0,0)
for o in bpy.data.objects:
 if o.type=='LIGHT' and o.name.startswith(('Highbay','Skylight wash','Front daylight','Reactor side')):o.data.energy*=CFG['lighting']['interior_scale']
bpy.context.scene.world.node_tree.nodes['Background'].inputs[1].default_value=CFG['lighting']['world_strength']
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
