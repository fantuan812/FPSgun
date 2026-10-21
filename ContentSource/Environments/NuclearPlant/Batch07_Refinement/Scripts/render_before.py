"""Render the untouched baseline in matched cameras / renderer for honest comparisons."""
import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent.parent;C=json.loads((R/'Config'/('design_v04.json' if (R/'Config/design_v04.json').exists() else 'design_v03.json' if (R/'Config/design_v03.json').exists() else ('design_v02.json' if (R/'Config/design_v02.json').exists() else 'design.json'))).read_text());bpy.ops.wm.open_mainfile(filepath=str(R/C['source']));s=bpy.context.scene
if (R/'Config/render_cameras.json').exists():C['cameras'].update(json.loads((R/'Config/render_cameras.json').read_text())['cameras'])
s.render.engine='BLENDER_EEVEE_NEXT';s.eevee.taa_render_samples=48;s.eevee.shadow_pool_size='1024';s.render.resolution_x=C['render']['width'];s.render.resolution_y=C['render']['height'];s.render.resolution_percentage=100
for name in ['site_overview','logistics_eye']:
 v=C['cameras'][name];d=bpy.data.cameras.new('B07 before '+name);o=bpy.data.objects.new(d.name,d);s.collection.objects.link(o);o.location=v['position'];o.rotation_euler=(Vector(v['target'])-o.location).to_track_quat('-Z','Y').to_euler();d.lens=v['lens'];d.clip_end=500;s.camera=o
 for c in bpy.data.collections:
  if c.name.startswith('B06_Proxy_'):c.hide_render=name!='site_overview'
 s.render.filepath=str(R/'renders'/('before_'+name+'.png'));bpy.ops.render.render(write_still=True)
