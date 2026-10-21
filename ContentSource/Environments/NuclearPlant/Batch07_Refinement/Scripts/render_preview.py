"""Fast visual gate before full-size rendering; same EEVEE renderer / lighting."""
import bpy,pathlib,json
R=pathlib.Path(__file__).resolve().parent.parent;bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'));s=bpy.context.scene;s.render.resolution_percentage=50;s.eevee.taa_render_samples=16
(R/'QA/visual_gates').mkdir(exist_ok=True)
for name in ['pump_eye','logistics_eye']:
 for c in bpy.data.collections:
  if c.name.startswith('B06_Proxy_'):c.hide_render=name!='site_overview'
 s.camera=bpy.data.objects[name];s.render.filepath=str(R/'QA/visual_gates'/f'{name}.png');bpy.ops.render.render(write_still=True)
