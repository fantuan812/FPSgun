"""EEVEE 48-sample serial rendering. CLI: -- [--before] view1 view2 ...
No simultaneous Blender process is allowed during this script.
"""
import bpy,json,pathlib,sys,math,hashlib,datetime
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent.parent
active_design=next(p for p in ['Config/design_v04.json','Config/design_v03.json','Config/design_v02.json','Config/design.json'] if (R/p).exists());C=json.loads((R/active_design).read_text())
script_sha=hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest();camera_config_sha=hashlib.sha256((R/'Config/render_cameras.json').read_bytes()).hexdigest() if (R/'Config/render_cameras.json').exists() else None
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['site_overview','site_cutaway','pump_eye','logistics_eye','pump_connection_eye','receiving_connection_eye','cargo_detail_eye','module_gallery']
preview='--preview' in args;before='--before' in args;args=[a for a in args if a not in ['--before','--preview']];src=(R/C['source']).resolve() if before else R/'site_refined.blend';sha=hashlib.sha256(src.read_bytes()).hexdigest()
if (R/'Config/render_cameras.json').exists():C['cameras'].update(json.loads((R/'Config/render_cameras.json').read_text())['cameras'])
bpy.ops.wm.open_mainfile(filepath=str(src));s=bpy.context.scene
# Same cameras are installed into either source, even the views introduced for B08.
for name,v in C['cameras'].items():
 old=bpy.data.objects.get(name)
 if old and old.type=='CAMERA':bpy.data.objects.remove(old,do_unlink=True)
 d=bpy.data.cameras.new(name);o=bpy.data.objects.new(name,d);s.collection.objects.link(o);o.location=v['position'];o.rotation_euler=(Vector(v['target'])-o.location).to_track_quat('-Z','Y').to_euler();d.lens=v['lens'];d.clip_end=500
s.render.engine='BLENDER_EEVEE_NEXT';s.eevee.taa_render_samples=48;s.eevee.shadow_pool_size='1024';s.render.resolution_x=C['render']['width'];s.render.resolution_y=C['render']['height'];s.render.resolution_percentage=100
if preview:s.render.resolution_x=960;s.render.resolution_y=600;s.eevee.taa_render_samples=24
initial_ob_hide={o.name:o.hide_render for o in s.objects};initial_col_hide={c.name:c.hide_render for c in bpy.data.collections};baseline_light_sig=[{'name':o.name,'type':o.data.type,'energy':o.data.energy,'matrix':[list(v) for v in o.matrix_world]} for o in s.objects if o.type=='LIGHT']
pp=R/'QA/render_provenance.json';provenance=json.loads(pp.read_text()) if pp.exists() else {}
for name in args:
 for o in s.objects:
  if o.name in initial_ob_hide:o.hide_render=initial_ob_hide[o.name]
 for c in bpy.data.collections:
  if c.name in initial_col_hide:c.hide_render=initial_col_hide[c.name]
 for cc in bpy.data.collections:
  if cc.name.startswith('B06_Proxy_'):cc.hide_render=name not in ['site_overview','site_cutaway']
 if name=='site_cutaway':
  for cn in ['02_Roof_Toggle','B06_Control_Roof','B06_Maintenance_Roof']:
   if cn in bpy.data.collections:bpy.data.collections[cn].hide_render=True
  for o in s.objects:
   if ('End wall panel' in o.name and o.location.y<0) or ('Side concrete panel' in o.name and o.location.x>0) or o.name.startswith('B06_P_hall roof') or (o.name.startswith('B07') and 'core_skin' in o.name):o.hide_render=True
 if name=='module_gallery':
  for o in s.objects:o.hide_render=True
  locations={'B08_SERVICE_EDGE':(-4,-1,0),'B08_SERVICE_EDGE_FLUSH':(-4,2,0),'B08_WALL_TERMINAL':(2,3,0),'B08_CARGO_DRESSING':(3,-1,0)}
  for idx,(mid,p) in enumerate(locations.items()):
   me=bpy.data.meshes[mid];ob=bpy.data.objects.new(mid+' GALLERY',me);s.collection.objects.link(ob);ob.location=p
   if C['modules'][mid]['bevel']:
    mod=ob.modifiers.new('manufactured edge','BEVEL');mod.width=C['modules'][mid]['bevel'];mod.segments=2
   if C['modules'][mid].get('base_module'):
    ob=bpy.data.objects.new('Retained B07 cargo base gallery',bpy.data.meshes[C['modules'][mid]['base_module']]);s.collection.objects.link(ob);ob.location=p
   d=bpy.data.curves.new('module caption','FONT');d.body=['01 / SERVICE EDGE','01B / FLUSH CROSSING','02 / WALL TERMINAL','03 / DRESSED CARGO'][idx];d.align_x='CENTER';d.size=.18;d.extrude=0;d.materials.append(bpy.data.materials['B08 steel']);ob=bpy.data.objects.new('module caption',d);s.collection.objects.link(ob);ob.location=(p[0],p[1]-1.75 if idx==3 else p[1]-.85,.012)
  bpy.ops.mesh.primitive_plane_add(size=100,location=(0,0,-.018));o=bpy.context.object;o.name='Gallery only floor';o.data.materials.append(bpy.data.materials['B08 concrete'])
  d=bpy.data.lights.new('Gallery only sun','SUN');d.energy=3;o=bpy.data.objects.new('Gallery only sun',d);s.collection.objects.link(o);o.rotation_euler=(.45,-.6,-.5)
  d=bpy.data.cameras.new('Gallery camera');o=bpy.data.objects.new('Gallery camera',d);s.collection.objects.link(o);o.location=(14,-19,17);o.rotation_euler=(Vector((-.5,.7,.8))-o.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=15.5;s.camera=o
 else:s.camera=bpy.data.objects['site_overview' if name=='site_cutaway' else name]
 key=('before_' if before else '')+('preview_' if preview else '')+name;s.render.filepath=str(R/'renders'/f'{key}.png');bpy.ops.render.render(write_still=True)
 provenance[key]={'source_scene':str(src),'active_design':active_design,'active_design_sha256':hashlib.sha256((R/active_design).read_bytes()).hexdigest(),'render_script_sha256':script_sha,'render_camera_config_sha256':camera_config_sha,'camera_type':s.camera.data.type,'camera_ortho_scale':s.camera.data.ortho_scale,'source_scene_sha256':sha,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'camera_position':list(s.camera.location),'camera_rotation':list(s.camera.rotation_euler),'camera_lens':s.camera.data.lens,'renderer':s.render.engine,'samples':s.eevee.taa_render_samples,'preview_only':preview,'resolution':[s.render.resolution_x,s.render.resolution_y],'baseline_lights':baseline_light_sig if name!='module_gallery' else 'Gallery only presentation lighting; not a before/after comparison.','image_sha256':hashlib.sha256((R/'renders'/f'{key}.png').read_bytes()).hexdigest()};pp.write_text(json.dumps(provenance,indent=2));print('B08_RENDER_DONE',key,flush=True)
 if (R/'QA/STOP_RENDER_AFTER_FRAME').exists():
  print('CONTROLLED_STOP_AFTER_SAVED_FRAME',flush=True);sys.exit(3)

