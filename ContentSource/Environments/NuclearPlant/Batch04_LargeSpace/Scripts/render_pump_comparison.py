import bpy,pathlib,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];records=[]
for label,path in [('before',R/'Region/pump_annex_before_comparison_only.blend'),('after',R/'Region/pump_annex_double_height_option.blend')]:
 bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=384;s.cycles.adaptive_min_samples=128;s.cycles.use_adaptive_sampling=True;s.cycles.adaptive_threshold=.025;s.cycles.use_denoising=False;s.cycles.max_bounces=4;s.cycles.diffuse_bounces=2;s.cycles.sample_clamp_indirect=2;s.render.resolution_x=1280;s.render.resolution_y=960;s.render.resolution_percentage=100
 if label=='before':
  with bpy.data.libraries.load(str(R/'Region/pump_annex_double_height_option.blend'),link=False) as (a,b):b.collections=['SCALE_REFERENCES_TOGGLE']
  s.collection.children.link(b.collections[0])
 for o in s.objects:
  if o.type=='LIGHT':o.hide_render=True
 for y in [-23,-15,-7]:
  bpy.ops.object.light_add(type='AREA',location=(-4,y,3.45));o=bpy.context.object;o.name='MATCHED_ANNEX_LIGHT';o.data.energy=700;o.data.size=3
 bpy.ops.object.light_add(type='AREA',location=(-4,-26,2.8));o=bpy.context.object;o.data.energy=1800;o.data.size=4;o.rotation_euler=(Vector((-4,-10,3))-o.location).to_track_quat('-Z','Y').to_euler()
 bpy.ops.object.camera_add(location=(-4,-25,1.65));c=bpy.context.object;c.data.type='PERSP';c.data.lens=24;c.data.clip_start=.05;c.rotation_euler=(Vector((-4,-8,2.2))-c.location).to_track_quat('-Z','Y').to_euler();s.camera=c;s.render.filepath=str(R/'Previews'/('pump_annex_'+label+'_eye.png'));bpy.ops.render.render(write_still=True);records.append({'label':label,'lens_mm':24,'camera_m':[-4,-25,1.65],'target_m':[-4,-8,2.2],'same_lighting':True,'engine':'Cycles','samples_max':384,'adaptive_min_samples':128,'adaptive_threshold':.025})
(R/'Validation/pump_eye_comparison.json').write_text(json.dumps(records,indent=2));print('PUMP_COMPARISON_COMPLETE',flush=True)
