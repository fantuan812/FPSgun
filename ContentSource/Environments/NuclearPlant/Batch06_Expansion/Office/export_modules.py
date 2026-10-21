import bpy,pathlib,json,math,sys
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parent;SOURCE=R.parent/'Regions/control.blend'
ids={'CTL_StairUnit':(18,41,0),'CTL_Deck':(-22,48,6),'CTL_Island':(2,47,0),'CTL_DisplayPanel':(-5.2,56.9,0)}
results=json.loads((R/'module_export_manifest.json').read_text()) if (R/'module_export_manifest.json').exists() else {}
if '--asset' in sys.argv:ids={k:v for k,v in ids.items() if k==sys.argv[sys.argv.index('--asset')+1]}
for aid,origin in ids.items():
 bpy.ops.wm.open_mainfile(filepath=str(SOURCE));objs=[o for o in bpy.data.objects if o.get('asset_id')==aid]
 if aid=='CTL_StairUnit':objs=[o for o in objs if o.get('module_instance')==0]
 if aid=='CTL_Deck':objs=[next(o for o in objs if abs(o.location.x+22)<.01 and abs(o.location.y-48)<.01)]
 keep=set(objs)
 for o in list(bpy.data.objects):
  if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
 for o in objs:o.matrix_world=Matrix.Translation(-Vector(origin))@o.matrix_world
 # Single clear collection, no other region hierarchy.
 s=bpy.context.scene;c=bpy.data.collections.new(aid);s.collection.children.link(c)
 for o in objs:
  for cc in list(o.users_collection):cc.objects.unlink(o)
  c.objects.link(o)
 for cc in list(bpy.data.collections):
  if cc!=c and cc.users==0:bpy.data.collections.remove(cc)
 for o in objs:o.select_set(True)
 s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
 d=R/'Assets'/aid;d.mkdir(parents=True,exist_ok=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(d/'model.blend'),compress=True)
 bpy.ops.export_scene.gltf(filepath=str(d/'export.glb'),export_format='GLB',use_selection=True,export_apply=True)
 corners=[o.matrix_world@Vector(v) for o in objs for v in o.bound_box];lo=[min(v[i] for v in corners) for i in range(3)];hi=[max(v[i] for v in corners) for i in range(3)]
 res={'asset_id':aid,'object_count':len(objs),'bounds_min':lo,'bounds_max':hi,'size':[hi[i]-lo[i] for i in range(3)],'reference':str(pathlib.Path('../../References')/(aid+'_prebuild_ortho.svg')),'origin_world_before_local':origin,'notes':{'CTL_StairUnit':'Walking datum rise2m/run3.4m; stringer and diagonal rail thickness extend AABB slightly.','CTL_Deck':'Origin top center; nominal4x3.6m thickness0.3m down.','CTL_Island':'Two steel panel mounting brackets included; floor-center origin.','CTL_DisplayPanel':'Nominal body depth0.4m; screen/text protrude approx0.041m.'}[aid]};(d/'dimensions.json').write_text(json.dumps(res,indent=2));results[aid]=res
 # Actual orthographic projection evidence (not the required prebuild reference).
 s.render.engine='CYCLES';s.cycles.samples=4;s.cycles.use_denoising=False;s.render.resolution_x=640;s.render.resolution_y=640;s.render.resolution_percentage=100;s.world=bpy.data.worlds.new('Module preview');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[1].default_value=.8
 for pos in [(-5,-7,9),(7,3,6)]:
  dd=bpy.data.lights.new('Softbox','AREA');dd.energy=800;dd.size=7;oo=bpy.data.objects.new('Softbox',dd);s.collection.objects.link(oo);oo.location=pos;oo.rotation_euler=(Vector((0,1,1))-oo.location).to_track_quat('-Z','Y').to_euler()
 center=Vector([(lo[i]+hi[i])/2 for i in range(3)]);scale=max(res['size'])*1.3
 for view,offset in [('front',(0,-20,0)),('right',(20,0,0)),('top',(0,0,20))]:
  dd=bpy.data.cameras.new(view);dd.type='ORTHO';dd.ortho_scale=scale;oo=bpy.data.objects.new(view,dd);s.collection.objects.link(oo);oo.location=center+Vector(offset);oo.rotation_euler=(center-oo.location).to_track_quat('-Z','Y').to_euler();s.camera=oo;s.render.filepath=str(d/(view+'.png'));bpy.ops.render.render(write_still=True)
(R/'module_export_manifest.json').write_text(json.dumps(results,indent=2))
