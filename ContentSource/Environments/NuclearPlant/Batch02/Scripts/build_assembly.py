import bpy,json,pathlib,math,sys
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];FIRST=R.parent
bpy.ops.wm.read_factory_settings(use_empty=True);s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1;s.render.engine='CYCLES';s.cycles.samples=64;s.cycles.use_denoising=False;s.cycles.max_bounces=6;s.render.resolution_x=1800;s.render.resolution_y=1250;s.render.resolution_percentage=100;s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('Architecture world');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.4,.48,.52,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.65
protos={};specs={};instances={};lineage=[]
for base,batch in [(R,2),(FIRST,1)]:
 for e in json.loads((base/'manifest.json').read_text())['assets']:
  sp=json.loads((base/e['path']/'spec.json').read_text());kind=sp['builder']
  if batch==1 and kind not in ['column','straight','stairs','rail_open']:continue
  with bpy.data.libraries.load(str(base/e['path']/'model.blend'),link=False) as (a,b):b.objects=[sp['asset_id']]
  protos[kind]=b.objects[0];specs[kind]=sp;lineage.append({'asset_id':sp['asset_id'],'source_batch':batch,'source':str((base/e['path']/'model.blend').relative_to(FIRST))})
def instance(key,kind,loc,deg=0):
 o=bpy.data.objects.new(key,protos[kind].data);bpy.context.collection.objects.link(o);o.matrix_world=Matrix.Translation(Vector(loc))@Matrix.Rotation(math.radians(deg),4,'Z');o.hide_render=False;o.hide_set(False);o['asset_id']=specs[kind]['asset_id'];instances[key]=(kind,o);return o
# Ground floor, outdoor approach and one corner enclosure.
for x in [0,4,8]:
 for y in [0,4]:instance(f'Floor_L0_{x}_{y}','floor',(x,y,0))
for y in [-12,-8,-4]:instance('Approach_'+str(y),'floor',(4,y,0))
instance('AnnexFloor','floor',(-5,4,0));instance('AnnexCorner','corner_wall',(-5,4,0))
# Ground-level facade with exact 2 m clear door and glazed sections.
for kind,x in [('solid_wall',0),('door_wall',4),('window_wall',8)]:instance('Front_L0_'+str(x),kind,(x,0,0))
for x in [4,8,12]:instance('Back_L0_'+str(x),'solid_wall',(x,8,0),180)
for x in [0,12]:
 for y in [0,4]:instance(f'Side_L0_{x}_{y}','window_wall' if y else 'solid_wall',(x,y,0),90)
# Mezzanine: T footprint. Floor slab underside is Z=3.75.
for x in [0,4,8]:instance('Floor_L1_'+str(x),'floor',(x,4,4))
instance('EntryFloor_L1','floor',(4,0,4));instance('EntryDoor_L1','door_wall',(4,0,4))
for x in [4,8,12]:instance('Back_L1_'+str(x),'window_wall' if x==8 else 'solid_wall',(x,8,4),180)
for x in [0,12]:instance('Side_L1_'+str(x),'window_wall',(x,4,4),90)
# Partial roof intentionally leaves central bay open for inspection.
for x in [0,8]:instance('Roof_L1_'+str(x),'roof',(x,4,8))
for x in [0,8]:instance('Roof_L0_'+str(x),'roof',(x,0,4))
# Exactly reuse Batch01 columns, seated 0.5 m into the foundation. New head adapters meet slab underside.
for i,(x,y) in enumerate([(1,5),(3,7),(5,5),(7,7),(9,5),(11,7),(5,1),(7,3)]):
 instance('Column_'+str(i),'column',(x,y,-.5));instance('ColumnHead_'+str(i),'column_head',(x,y,3.5))
# Mezzanine edge guards from Batch01.
for x in [0,8]:instance('FrontGuard_'+str(x),'rail_open',(x,4,4))
for x in [4,8]:instance('EntryGuard_'+str(x),'rail_open',(x,0,4),90)
# Two 2m-rise flights plus 4m straight catwalk lead directly through the upper door.
instance('StairLower','stairs',(6,-12,0),90);instance('StairUpper','stairs',(6,-8,2),90);instance('EntryCatwalk','straight',(6,-4,4),90)
for x in [5.25,6.75]:instance('CatwalkSupport_'+str(x),'column',(x,-2,-.2))
def material(n,c):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*c,1);m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.75;return m
ground=material('CONTEXT_Ground',(.13,.18,.20));concrete=material('CONTEXT_Foundation',(.28,.34,.36));white=material('PRESENTATION_White',(.80,.87,.88));yellow=material('PRESENTATION_Yellow',(.86,.57,.12))
def cube(name,loc,d,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);b=o.modifiers.new('edge','BEVEL');b.width=.02;b.segments=2;return o
cube('CONTEXT_Foundation',(3,-2,-.50),(26,30,.5),ground)
cube('CONTEXT_IntermediateStairPier',(6,-8,.775),(2,.5,2.05),concrete) # top 1.80 m matches stair underside at mid-flight
for body,loc,size,mat in [('NPP / SECTOR K-17',(-7,-13,-.24),.65,white),('ARCHITECTURE KIT  /  BATCH 02',(-7,-14,-.24),.26,yellow),('OPEN ROOF = INSPECTION CUTAWAY',(-7,-14.6,-.24),.18,white)]:
 bpy.ops.object.text_add(location=loc);o=bpy.context.object;o.name='LABEL_'+body;o.data.body=body;o.data.size=size;o.data.extrude=.002;o.data.materials.append(mat)
for name,loc,en,size in [('KEY',(-12,-15,25),6500,16),('FILL',(20,-2,17),4500,12),('RIM',(3,17,20),6000,12)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=en;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((4,0,3))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(28,-35,27));cam=bpy.context.object;cam.name='Architecture_beauty_ORTHO';cam.rotation_euler=(Vector((3,-1,3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=36;s.camera=cam
# Verify seam and support measurements using actual imported geometry bounds and declared sockets.
def socket(key,id):
 kind,o=instances[key];sc=next(x for x in specs[kind]['connection_sockets'] if x['id']==id);return o.matrix_world@Vector(sc['position_m']),o.matrix_world.to_3x3()@Vector(sc['outward_normal'])
links=[('StairLower','upper','StairUpper','lower'),('StairUpper','upper','EntryCatwalk','start'),('EntryCatwalk','end','EntryDoor_L1','passage'),('EntryCatwalk','end','EntryFloor_L1','south')];checks=[]
for a,sa,b,sb in links:
 pa,na=socket(a,sa);pb,nb=socket(b,sb);gap=(pa-pb).length;dot=na.dot(nb);checks.append({'connection':a+':'+sa+' -> '+b+':'+sb,'gap_m':gap,'normals_dot':dot,'status':'PASS' if gap<1e-5 and dot<-.99999 else 'FAIL'})
def bounds(key):
 kind,o=instances[key];v=[o.matrix_world@x.co for x in o.data.vertices];return [min(x[a] for x in v) for a in range(3)],[max(x[a] for x in v) for a in range(3)]
for i in range(8):
 cmn,cmx=bounds('Column_'+str(i));hmn,hmx=bounds('ColumnHead_'+str(i));floor_key=['Floor_L1_0','Floor_L1_0','Floor_L1_4','Floor_L1_4','Floor_L1_8','Floor_L1_8','EntryFloor_L1','EntryFloor_L1'][i];floorbottom=bounds(floor_key)[0][2];g1=hmn[2]-cmx[2];g2=floorbottom-hmx[2];checks.append({'connection':'column/head/slab '+str(i),'floor_instance':floor_key,'column_to_head_gap_m':g1,'head_to_slab_gap_m':g2,'status':'PASS' if max(abs(g1),abs(g2))<1e-5 else 'FAIL'})
report={'status':'PASS' if all(x['status']=='PASS' for x in checks) else 'FAIL','checks':checks,'lineage':lineage,'placements':[{'instance':k,'asset_id':specs[t]['asset_id'],'matrix_world':[list(row) for row in o.matrix_world]} for k,(t,o) in instances.items()],'notes':['Batch01 source assets appended read-only; original files unchanged.','Intermediate stair foundation is context geometry, not a new exported modular asset.','Roof omitted over central bay deliberately for interior inspection.','Building is a maintenance/control-area sample assembly, not the completed whole-site environment.','Blender numeric checks only; actual UE traversal remains untested.']}
(R/'Validation/assembly_validation.json').write_text(json.dumps(report,indent=2));bpy.ops.wm.save_as_mainfile(filepath=str(R/'architecture_demo.blend'))
if '--validate-only' in sys.argv:
 print('ASSEMBLY_VALIDATE_COMPLETE',report['status'],flush=True);sys.exit(0)
s.render.filepath=str(R/'Previews/architecture_beauty.png');bpy.ops.render.render(write_still=True)
cam.location=(4,0,45);cam.rotation_euler=(0,0,0);cam.data.ortho_scale=33;s.render.resolution_x=1400;s.render.resolution_y=1400;s.render.filepath=str(R/'Previews/architecture_top.png');bpy.ops.render.render(write_still=True)
print('ASSEMBLY_COMPLETE',report['status'],flush=True)
