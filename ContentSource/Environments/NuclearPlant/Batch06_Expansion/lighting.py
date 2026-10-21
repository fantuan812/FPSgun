"""Configuration-driven lighting only. Does not edit materials or scene geometry."""
import bpy,math

def apply(scene,cfg):
 c=cfg['lighting']
 for name,conf in [('B06 daylight',c['key_sun']),('B06 exterior fill',c['fill_sun'])]:
  o=bpy.data.objects.get(name)
  if o is None:
   d=bpy.data.lights.new(name,'SUN');o=bpy.data.objects.new(name,d);scene.collection.objects.link(o)
  o.data.energy=conf['energy'];o.data.angle=math.radians(conf['angle_deg']);o.data.color=conf['color'];o.rotation_euler=[math.radians(v) for v in conf['rotation_deg']]
 scene.world.use_nodes=True
 bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND')
 bg.inputs['Color'].default_value=(*c['world_color'],1);bg.inputs['Strength'].default_value=c['world_strength']
 scene.view_settings.exposure=c['exposure']
