"""Replace one original graybox zone. Preserve Batch01/02 files; save region and whole-site copy in Batch03."""
import bpy,json,pathlib,math,sys
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];FIRST=R.parent;spec=json.loads((R/'Region/zone_spec.json').read_text());RENDER='--no-render' not in sys.argv
bpy.ops.wm.read_factory_settings(use_empty=True);s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1;s.render.engine='CYCLES';s.cycles.samples=64;s.cycles.use_denoising=False;s.cycles.max_bounces=6;s.view_settings.view_transform='AgX';s.render.resolution_x=1900;s.render.resolution_y=1350;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Pump yard daylight');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.51,.56,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.65
zone=bpy.data.collections.new('04_PUMP_REALIZED');s.collection.children.link(zone);protos={};specs={};lineage=[];instances={}
for batch,root,kinds in [(1,FIRST,spec['reuses']['batch01']),(2,FIRST/'Batch02',spec['reuses']['batch02']),(3,R,None)]:
 for e in json.loads((root/'manifest.json').read_text())['assets']:
  sp=json.loads((root/e['path']/'spec.json').read_text());kind=sp['builder']
  if kinds is not None and kind not in kinds:continue
  with bpy.data.libraries.load(str(root/e['path']/'model.blend'),link=False) as (a,b):b.objects=[sp['asset_id']]
  protos[kind]=b.objects[0];specs[kind]=sp;lineage.append({'asset_id':sp['asset_id'],'source_batch':batch,'source':str((root/e['path']/'model.blend').relative_to(FIRST))})
def inst(key,kind,loc,deg=0,extra=None):
 o=bpy.data.objects.new(key,protos[kind].data);zone.objects.link(o);o.matrix_world=Matrix.Translation(Vector(loc))@Matrix.Rotation(math.radians(deg),4,'Z')@(extra if extra is not None else Matrix.Identity(4));o.hide_render=False;o.hide_set(False);o['asset_id']=specs[kind]['asset_id'];instances[key]=(kind,o);return o
# One continuous grid of 48 reused floor modules, exactly the original 32 x 24 m footprint.
for x in range(-8,24,4):
 for y in range(-28,-4,4):inst(f'Ground_{x}_{y}','floor',(x,y,0))
for y in [-40,-36,-32]:inst('ExternalApproach_'+str(y),'floor',(20,y,0))
# Two-level maintenance annex along west side. Interior stays deliberately sparse.
for x in [-7.75,-3.75]:
 for y in range(-28,-4,4):inst(f'UpperFloor_{x}_{y}','floor',(x,y,4));inst(f'Roof_{x}_{y}','roof',(x,y,spec['building']['roof_bottom_z']))
for z in [0,4]:
 for x in [-7.75,-3.75]:
  inst(f'SouthWall_{x}_{z}','door_wall' if x==-3.75 and z==0 else 'window_wall',(x,-27.75,z))
  inst(f'NorthWall_{x}_{z}','window_wall',(x,-4.25,z))
 for y in range(-28,-4,4):
  inst(f'WestWall_{y}_{z}','window_wall' if y in [-24,-12] else 'solid_wall',(-7.75,y,z),90)
  kind='door_wall' if (z==0 and y==-28) or (z==4 and y==-8) else ('window_wall' if y in [-24,-16] else 'solid_wall')
  inst(f'EastWall_{y}_{z}',kind,(.25,y,z),90)
for i,(x,y) in enumerate([(x,y) for x in [-5.75,-1.75] for y in [-26,-18,-10]]):
 inst('BuildingColumn_'+str(i),'column',(x,y,-.5));inst('BuildingHead_'+str(i),'column_head',(x,y,3.5))
# The upper route is continuous from the building door to the east stair.
for i,x in enumerate([.25,4.25,8.25,12.25]):inst('NorthWalk_'+str(i),'straight',(x,-6,4))
inst('NorthEastCorner','corner',(19.25,-9,4),90)
for i,y in enumerate([-13,-17]):inst('EastWalk_'+str(i),'straight',(19.25,y,4),90)
inst('StairUpper','stairs',(19.25,-21,2),90);inst('StairLower','stairs',(19.25,-25,0),90)
for i,(x,y) in enumerate([(2.25,-5.25),(6.25,-5.25),(10.25,-5.25),(14.25,-5.25),(19.25,-7),(18.5,-11),(18.5,-15)]):inst('WalkColumn_'+str(i),'column',(x,y,-.2))
# Parallel pump trains; actual matching flange positions throughout.
for i,y in enumerate([-20,-14,-8]):
 inst(f'InletTee_{i}','pipe_tee',(1,y+1,2),-90)
 inst(f'SuctionValve_{i}','valve',(2,y,2))
 inst(f'SuctionPipe_{i}','pipe',(3,y,2))
 inst(f'Pump_{i}','pump',(7,y,1))
 # Rotate the XY elbow over its local X axis, then +90 in Z: +Y inlet turns +X.
 inst(f'DischargeElbow_{i}','elbow',(8.5,y+1,2),90,Matrix.Rotation(math.pi,4,'X'))
 inst(f'DischargeValve_{i}','valve',(9.5,y+2,2))
 inst(f'DischargePipe_{i}','pipe',(10.5,y+2,2))
 inst(f'ReturnTee_{i}','pipe_tee',(15.5,y+1,2),90)
for i,y in enumerate([-19,-13]):inst(f'InletHeader_{i}','pipe',(1,y,2),90)
for i,y in enumerate([-17,-11]):inst(f'ReturnHeader_{i}','pipe',(15.5,y,2),90)
# Reused paired saddles: one active pipe and one spare seat on each support.
for i,y in enumerate([-17,-11]):inst(f'InletSupport_{i}','pipe_support',(1.5,y,0))
for i,y in enumerate([-15,-9]):inst(f'ReturnSupport_{i}','pipe_support',(16,y,0))
# Context-only pads, signage and end caps; all listed separately from exported kit assets.
def mat(n,c,metal=0):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.65;p.inputs['Metallic'].default_value=metal;return m
concrete=mat('CONTEXT_PumpPlinth',(.24,.30,.32));yellow=mat('CONTEXT_MarkingYellow',(.86,.52,.06));white=mat('CONTEXT_MarkingWhite',(.78,.86,.85));dark=mat('CONTEXT_LabelBacking',(.07,.11,.13));metal=mat('CONTEXT_BlindFlange',(.4,.48,.5),.7)
def move_zone(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 zone.objects.link(o)
def cube(n,c,d,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);o=bpy.context.object;o.name=n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);move_zone(o);b=o.modifiers.new('Context edge bevel','BEVEL');b.width=.015;b.segments=2;return o
def label(n,text,c,size,rotation=(0,0,0),m=white):
 bpy.ops.object.text_add(location=c,rotation=rotation);o=bpy.context.object;o.name=n;o.data.body=text;o.data.size=size;o.data.extrude=.001;o.data.materials.append(m);move_zone(o)
for i,y in enumerate([-20,-14,-8]):
 cube('CONTEXT_ProcessPlinth_'+str(i),(9,y,.5),(4,2,1),concrete);label('LABEL_PUMP_'+str(i),'P-0'+str(i+1),(7.25,y-1.018,.3),.38,(math.pi/2,0,0))
# A low threshold ramp bridges the original road top (0.07 m) to the access-apron floor (0 m).
mesh=bpy.data.meshes.new('AccessThresholdRamp');mesh.from_pydata([(20.25,-40,.07),(24,-40,.07),(24,-39,0),(20.25,-39,0),(20.25,-40,-.1),(24,-40,-.1),(24,-39,-.1),(20.25,-39,-.1)],[],[(0,1,2,3),(7,6,5,4),(4,5,1,0),(5,6,2,1),(6,7,3,2),(7,4,0,3)]);ob=bpy.data.objects.new('CONTEXT_RoadThresholdRamp',mesh);zone.objects.link(ob);mesh.materials.append(concrete)
cube('CONTEXT_StairPier',(19.25,-21,.775),(2,.5,2.05),concrete)
for y in range(-27,-4,2):cube('CONTEXT_LaneDash_'+str(y),(21,y,.006),(.10,1,.012),yellow)
label('LABEL_ZONE','04 / PUMP YARD',(20.9,-25,.022),.35,(0,0,math.pi/2));label('LABEL_PROCESS','WATER TREATMENT / P-01-03',(4,-27,.022),.44)
# Four terminal reserve connections have blind plates, rather than unexplained open pipe ends.
for i,(x,y,out) in enumerate([(1,-21,-1),(1,-7,1),(15.5,-19,-1),(15.5,-5,1)]):
 bpy.ops.mesh.primitive_cylinder_add(vertices=40,radius=.375,depth=.06,location=(x,y+out*.03,2),rotation=(math.pi/2,0,0));o=bpy.context.object;o.name='CONTEXT_BlindHeaderCap_'+str(i);o.data.materials.append(metal);move_zone(o)
# Actual interface checks, route topology and process network checks.
def socket(k,id):
 kind,o=instances[k];sc=next(x for x in specs[kind]['connection_sockets'] if x['id']==id);return o.matrix_world@Vector(sc['position_m']),o.matrix_world.to_3x3()@Vector(sc['outward_normal'])
links=[('EastWall_-8_4','passage','NorthWalk_0','start')]+[(f'NorthWalk_{i}','end',f'NorthWalk_{i+1}','start') for i in range(3)]+[('NorthWalk_3','end','NorthEastCorner','turn'),('NorthEastCorner','start','EastWalk_0','end'),('EastWalk_0','start','EastWalk_1','end'),('EastWalk_1','start','StairUpper','upper'),('StairUpper','lower','StairLower','upper')]
for i in range(3):links += [(f'InletTee_{i}','branch',f'SuctionValve_{i}','in'),(f'SuctionValve_{i}','out',f'SuctionPipe_{i}','in'),(f'SuctionPipe_{i}','out',f'Pump_{i}','in'),(f'Pump_{i}','out',f'DischargeElbow_{i}','in'),(f'DischargeElbow_{i}','out',f'DischargeValve_{i}','in'),(f'DischargeValve_{i}','out',f'DischargePipe_{i}','in'),(f'DischargePipe_{i}','out',f'ReturnTee_{i}','branch')]
for i in range(2):links += [(f'InletTee_{i}','in',f'InletHeader_{i}','in'),(f'InletHeader_{i}','out',f'InletTee_{i+1}','out'),(f'ReturnTee_{i}','out',f'ReturnHeader_{i}','in'),(f'ReturnHeader_{i}','out',f'ReturnTee_{i+1}','in')]
checks=[]
for a,sa,b,sb in links:
 pa,na=socket(a,sa);pb,nb=socket(b,sb);gap=(pa-pb).length;dot=na.dot(nb);checks.append({'connection':f'{a}:{sa} -> {b}:{sb}','gap_m':gap,'normals_dot':dot,'status':'PASS' if gap<1e-5 and dot<-.99999 else 'FAIL'})
# Verify actual saddle/pipe tangent heights with rays in the imported meshes, not only labels.
def worldray(key,start,direction,distance):
 kind,o=instances[key];inv=o.matrix_world.inverted();ok,loc,n,idx=o.ray_cast(inv@Vector(start),inv.to_3x3()@Vector(direction),distance=distance);return o.matrix_world@loc if ok else None
for header,support,x,ys in [('InletHeader','InletSupport',1,[-17,-11]),('ReturnHeader','ReturnSupport',15.5,[-15,-9])]:
 for i,y in enumerate(ys):
  pp=worldray(f'{header}_{i}',(x,y,1.6),(0,0,1),.3);ss=worldray(f'{support}_{i}',(x,y,1.85),(0,0,-1),.3);gap=abs(pp.z-ss.z) if pp is not None and ss is not None else 999;checks.append({'test':'actual pipe to reused saddle seating','header':f'{header}_{i}','support':f'{support}_{i}','gap_m':gap,'status':'PASS' if gap<.002 else 'FAIL'})
# All realized visible geometry must stay within the original footprint and height; foundations may extend below Z=0.
verts=[o.matrix_world@v.co for key,(kind,o) in instances.items() if not key.startswith('ExternalApproach_') for v in o.data.vertices];mn=[min(v[a] for v in verts) for a in range(3)];mx=[max(v[a] for v in verts) for a in range(3)];envelope_ok=mn[0]>=-8.00001 and mx[0]<=24.00001 and mn[1]>=-28.00001 and mx[1]<=-3.99999 and mx[2]<=8.00001
checks.append({'test':'original zone module envelope','min_m':mn,'max_m':mx,'undergrade_allowed_m':.5,'excluded_external_approach_tiles':3,'status':'PASS' if envelope_ok else 'FAIL'})
# Keep east logistics lane free above the floor: check actual object bounds against the reserved prism.
lane=(20.25,24,-28,-4,.05,3);violations=[]
for key,(kind,o) in instances.items():
 if kind in ['floor']:continue
 v=[o.matrix_world@x.co for x in o.data.vertices];lo=[min(x[a] for x in v) for a in range(3)];hi=[max(x[a] for x in v) for a in range(3)]
 if hi[0]>lane[0]+1e-5 and lo[0]<lane[1]-1e-5 and hi[1]>lane[2] and lo[1]<lane[3] and hi[2]>lane[4] and lo[2]<lane[5]:violations.append(key)
checks.append({'test':'east 3.75 m ground service lane reserved prism','violations':violations,'status':'PASS' if not violations else 'FAIL'})
report={'status':'PASS' if all(x['status']=='PASS' for x in checks) else 'FAIL','zone_id':'04_PUMP','checks':checks,'lineage':lineage,'placements':[{'instance':k,'asset_id':specs[t]['asset_id'],'matrix_world':[list(row) for row in o.matrix_world]} for k,(t,o) in instances.items()],'context_geometry':['3 raised process plinths','intermediate stair pier','paint markings and labels','4 blind reserve flange plates','one low threshold ramp to existing south road'],'limits':['Only 04_PUMP is replaced; seven other zones stay graybox.','Basic PBR, not final realistic art.','Ground-lane AABB and socket checks are not UE character or vehicle tests.','Header branches communicate geometrically; no fluid/pressure or real engineering simulation.','Upper route connects to ground by east stair, not yet to the global elevated route.']};(R/'Validation/region_validation.json').write_text(json.dumps(report,indent=2));(R/'Region/placements.json').write_text(json.dumps({'units':'meters','axis':'Blender Z up','lineage':lineage,'placements':report['placements']},indent=2))
# Lighting and region camera.
for name,loc,power,size in [('KEY',(-6,-35,40),18000,25),('FILL',(35,-10,25),10000,20),('RIM',(0,15,30),16000,20)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((8,-16,2))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(46,-59,40));cam=bpy.context.object;cam.name='PumpZone_Beauty_ORTHO';cam.rotation_euler=(Vector((8,-21,2.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=54;s.camera=cam
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region/pump_zone.blend'))
if RENDER:
 s.render.filepath=str(R/'Previews/pump_zone_beauty.png');bpy.ops.render.render(write_still=True)
 cam.location=(8,-22,60);cam.rotation_euler=(0,0,0);cam.data.ortho_scale=44;s.render.resolution_x=1600;s.render.resolution_y=1400;s.render.filepath=str(R/'Previews/pump_zone_top.png');bpy.ops.render.render(write_still=True)
if RENDER:
 cam.location=(27,-32,14);cam.rotation_euler=(Vector((9,-17,2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=20;s.render.resolution_x=1600;s.render.resolution_y=1200;s.render.filepath=str(R/'Previews/pump_train_detail.png');bpy.ops.render.render(write_still=True)
# Add original graybox objects except the replaced box and label. Save a separate integrated-site copy.
with bpy.data.libraries.load(str(FIRST/'Blockout/site_graybox.blend'),link=False) as (a,b):b.objects=[n for n in a.objects if n not in ['04_PUMP','Label_04_PUMP'] and not n.startswith(('Camera','Area'))]
context=bpy.data.collections.new('OTHER_7_ZONES_GRAYBOX');s.collection.children.link(context)
for o in b.objects:
 if o is not None and o.type not in ['CAMERA','LIGHT']:context.objects.link(o)
# Recess ONLY the copied site ground beneath new floor tiles; equal Z=0 faces otherwise z-fight.
ground=bpy.data.objects.get('SITE_224x192')
for x0,x1,y0,y1 in [(-8,24,-28,-4),(20,24,-40,-28)]:
 bpy.ops.mesh.primitive_cube_add(size=1,location=((x0+x1)/2,(y0+y1)/2,.37));cut=bpy.context.object;cut.dimensions=(x1-x0,y1-y0,1.26);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);bpy.context.view_layer.objects.active=ground;mod=ground.modifiers.new('Recess below realized floor','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
ground['batch03_ground_recess_m']=.26
cam.location=(160,-215,185);cam.rotation_euler=(Vector((0,0,5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=270;s.render.resolution_x=1800;s.render.resolution_y=1400;s.cycles.samples=48
# Full-site soft key avoids relying on region-sized illumination.
bpy.ops.object.light_add(type='AREA',location=(-60,-80,160));o=bpy.context.object;o.data.energy=200000;o.data.size=150
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region/site_with_pump_zone.blend'))
if RENDER:s.render.filepath=str(R/'Previews/site_with_pump_zone.png');bpy.ops.render.render(write_still=True)
print('PUMP_ZONE_COMPLETE',report['status'],len(instances),len(checks),flush=True)
