import bpy,pathlib,json,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
for label,path in [('after',R/'Region/pump_service_connected.blend'),('before',R/'Region/service_compact_comparison_only.blend')]:
 bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=384;s.cycles.adaptive_min_samples=128;s.cycles.use_adaptive_sampling=True;s.cycles.adaptive_threshold=.025;s.cycles.sample_clamp_indirect=2;s.cycles.caustics_reflective=False;s.cycles.caustics_refractive=False;s.cycles.max_bounces=4;s.cycles.diffuse_bounces=2;s.cycles.use_denoising=False;s.render.resolution_x=1280;s.render.resolution_y=854;s.render.resolution_percentage=100
 if label=='before':
  with bpy.data.libraries.load(str(R/'Region/pump_service_connected.blend'),link=False) as (a,b):b.collections=['SCALE_REFERENCES_TOGGLE']
  s.collection.children.link(b.collections[0])

 for o in s.objects:
  if o.type=='LIGHT':o.hide_render=True
  if o.name.startswith('CAPSULE_'):o.location.x=-15;o.location.y=-60
 for m in bpy.data.materials:
  if 'HighBayLuminaire' in m.name and m.use_nodes:m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=0
 for x in [-18,-6]:
  for y in [-67,-61,-55]:
   bpy.ops.object.light_add(type='AREA',location=(x,y,3.5));l=bpy.context.object;l.name='MATCHED_REVIEW_LIGHT';l.data.energy=900;l.data.size=4
 s.world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.51,.56,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.7
 bpy.ops.object.light_add(type='AREA',location=(-9,-51.8,4));fill=bpy.context.object;fill.name='SCALE_REVIEW_FRONT_FILL';fill.data.energy=5000;fill.data.size=8;fill.rotation_euler=(Vector((-9,-64,3))-fill.location).to_track_quat('-Z','Y').to_euler()
 bpy.ops.object.camera_add(location=(-9,-52.5,1.65));cam=bpy.context.object;cam.data.type='PERSP';cam.data.lens=24;cam.data.clip_start=.05;cam.rotation_euler=(Vector((-11,-67,3.4))-cam.location).to_track_quat('-Z','Y').to_euler();s.camera=cam;s.render.filepath=str(R/'Previews'/('hall_'+label+'_eye_1p65m.png'));bpy.ops.render.render(write_still=True)
 report={'label':label,'camera_position_m':list(cam.location),'eye_height_m':1.65,'lens_mm':24,'projection':'PERSP','target_m':[-11,-67,3.4],'engine':'Cycles','samples_max':384,'adaptive_min_samples':128,'adaptive_threshold':.025,'review_fill_light':'Both scenes: identical world, six 900 W 4 m area lamps at Z=3.5, one 5000 W 8 m front fill. Original lights disabled. Same sampling and camera. Capsule moved to side at (-15,-60).'};reports.append(report)
 if label=='after':
  cam.location=(-23.5,-68.5,1.65);cam.rotation_euler=(Vector((1,-55,4))-cam.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(R/'Previews/hall_after_eye_across_span.png');bpy.ops.render.render(write_still=True)
  groups={i:[o for o in s.objects if o.name.startswith(f'HUMAN_{i}_') or o.name.startswith(f'CONTEXT_HUMAN_{i}_')] for i in range(4)};sizes=[]
  for i,obs in groups.items():
   v=[o.matrix_world@x.co for o in obs for x in o.data.vertices];sizes.append({'id':i,'height_m':max(x.z for x in v)-min(x.z for x in v)})
  cap=[o for o in s.objects if o.name.startswith('CAPSULE_')];v=[o.matrix_world@x.co for o in cap for x in o.data.vertices];reports.append({'actual_scale_geometry':{'human_heights':sizes,'capsule_diameter_m':max(x.x for x in v)-min(x.x for x in v),'capsule_height_m':max(x.z for x in v)-min(x.z for x in v)}})
(R/'Validation/eye_height_comparison.json').write_text(json.dumps(reports,indent=2))
