import bpy,json,pathlib,sys,math,hashlib,datetime
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent.parent
C=json.loads((R/'Config'/('design_v04.json' if (R/'Config/design_v04.json').exists() else 'design_v03.json' if (R/'Config/design_v03.json').exists() else ('design_v02.json' if (R/'Config/design_v02.json').exists() else 'design.json'))).read_text())
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['site_overview','site_cutaway','core_entry','pump_eye','logistics_eye']
bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'));s=bpy.context.scene
source_scene_sha256=hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest()
provenance_path=R/'QA/render_provenance.json'
provenance=json.loads(provenance_path.read_text()) if provenance_path.exists() else {}
cut_cols=['02_Roof_Toggle','B06_Control_Roof','B06_Maintenance_Roof']
cut_objects=[o for o in s.objects if ('End wall panel' in o.name and o.location.y<0) or ('Side concrete panel' in o.name and o.location.x>0) or o.name.startswith('B06_P_hall roof') or (o.name.startswith('B07') and 'core_skin' in o.name)]
for name in args:
 cut=name=='site_cutaway'
 for cc in bpy.data.collections:
  if cc.name.startswith('B06_Proxy_'):cc.hide_render=name not in ['site_overview','site_cutaway']
 for cn in cut_cols:
  if cn in bpy.data.collections:bpy.data.collections[cn].hide_render=cut
 for o in cut_objects:o.hide_render=cut
 if name=='module_gallery':
  # Re-open module meshes into a separate curated gallery, no full-scene clutter.
  for o in list(s.objects):o.hide_render=True
  for i,mid in enumerate(C['modules']):
   me=bpy.data.meshes.get(mid);ob=bpy.data.objects.new(mid+' gallery',me);s.collection.objects.link(ob);ob.location=((i%3)*12,(i//3)*11,0)
   mod=ob.modifiers.new('edge radius','BEVEL');mod.width=C['modules'][mid].get('bevel_m',.012);mod.segments=2
   tx=bpy.data.curves.new('module label','FONT');tx.body=f'{i+1:02d} / '+mid.replace('B07_','');tx.size=.42;tx.align_x='CENTER';tx.materials.append(bpy.data.materials['B07 steel']);to=bpy.data.objects.new('gallery label',tx);s.collection.objects.link(to);to.location=((i%3)*12,(i//3)*11-4,.015)
  # Exact narrow stock-family variant; geometry was frozen on the v04 orthographic sheet.
  if C.get('variants'):
   ob=bpy.data.objects.new('Narrow cabinet variant gallery',bpy.data.meshes['B07_SERVICE_CABINET']);s.collection.objects.link(ob);ob.location=(12,22,0);ob.scale=(.45,1,1);mod=ob.modifiers.new('edge radius','BEVEL');mod.width=.006;mod.segments=2
   tx=bpy.data.curves.new('variant label','FONT');tx.body='07a / NARROW VARIANT';tx.size=.42;tx.align_x='CENTER';tx.materials.append(bpy.data.materials['B07 steel']);to=bpy.data.objects.new('variant label',tx);s.collection.objects.link(to);to.location=(12,18,.015)
  bpy.ops.mesh.primitive_plane_add(size=200,location=(10,4,-.02));floor=bpy.context.object;floor.name='Gallery floor';floor.data.materials.append(bpy.data.materials.get('B07 concrete'))
  d=bpy.data.lights.new('Gallery sun','SUN');d.energy=3;o=bpy.data.objects.new('Gallery sun',d);s.collection.objects.link(o);o.rotation_euler=(.45,-.6,-.5)
  d=bpy.data.cameras.new('Gallery camera');o=bpy.data.objects.new('Gallery camera',d);s.collection.objects.link(o);o.location=(43,-48,38);o.rotation_euler=(Vector((11,9,2))-o.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=44;s.camera=o
 else:s.camera=bpy.data.objects['site_overview' if cut else name]
 s.render.filepath=str(R/'renders'/f'{name}.png');bpy.ops.render.render(write_still=True)
 provenance[name]={'scene_sha256':source_scene_sha256,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'camera_position':list(s.camera.location),'camera_lens':s.camera.data.lens,'renderer':s.render.engine,'samples':s.eevee.taa_render_samples,'image_sha256':hashlib.sha256((R/'renders'/f'{name}.png').read_bytes()).hexdigest()};provenance_path.write_text(json.dumps(provenance,indent=2))
 print('B07_RENDER_DONE',name)
