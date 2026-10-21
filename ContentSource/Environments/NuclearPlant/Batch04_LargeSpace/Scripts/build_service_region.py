"""Batch04: realize service/logistics zone and connect it to the frozen pump assembly in a new scene."""
import bpy,json,pathlib,math,sys
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];F=R.parent;RENDER='--no-render' not in sys.argv
bpy.ops.wm.read_factory_settings(use_empty=True);s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1;s.render.engine='CYCLES';s.cycles.samples=64;s.cycles.use_denoising=False;s.cycles.max_bounces=6;s.view_settings.view_transform='AgX';s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Connected industrial districts daylight');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.51,.56,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.7
# Actual Batch03 meshes are appended, not linked. Prior source files stay untouched.
with bpy.data.libraries.load(str(F/'Batch03/Region/pump_zone.blend'),link=False) as (a,b):b.collections=['04_PUMP_REALIZED']
pump=b.collections[0];s.collection.children.link(pump)
zone=bpy.data.collections.new('07_SERVICE_REALIZED');s.collection.children.link(zone)
linkcoll=bpy.data.collections.new('PUMP_SERVICE_CONNECTIONS');s.collection.children.link(linkcoll)
roofcoll=bpy.data.collections.new('SERVICE_ROOF_TOGGLE');s.collection.children.link(roofcoll)
protos={};specs={};lineage=[];instances={};reused_pump=[]
for batch,root in [(1,F),(2,F/'Batch02'),(3,F/'Batch03'),(4,R)]:
 for e in json.loads((root/'manifest.json').read_text())['assets']:
  sp=json.loads((root/e['path']/'spec.json').read_text());kind=sp['builder']
  existing=next((o for o in pump.objects if o.get('asset_id')==sp['asset_id']),None)
  if existing is None:
   with bpy.data.libraries.load(str(root/e['path']/'model.blend'),link=False) as (a,b):b.objects=[sp['asset_id']]
   existing=b.objects[0]
  protos[kind]=existing;specs[kind]=sp;lineage.append({'asset_id':sp['asset_id'],'source_batch':batch,'source':str((root/e['path']/'model.blend').relative_to(F))})
id_kind={v['asset_id']:k for k,v in specs.items()}
for o in pump.objects:
 if o.get('asset_id'):
  instances['PUMP__'+o.name]=(id_kind[o['asset_id']],o);reused_pump.append(o.name)
def inst(key,kind,loc,deg=0,coll=None):
 o=bpy.data.objects.new(key,protos[kind].data);(coll or zone).objects.link(o);o.matrix_world=Matrix.Translation(Vector(loc))@Matrix.Rotation(math.radians(deg),4,'Z');o.hide_render=False;o.hide_set(False);o['asset_id']=specs[kind]['asset_id'];instances[key]=(kind,o);return o
# Replace only one instantiated walkway IN THIS COPY, preserving the pump's original down-stair branch.
old=instances.pop('PUMP__EastWalk_1')[1];bpy.data.objects.remove(old,do_unlink=True);inst('PumpLinkTee','tee',(19.25,-13,4),-90,linkcoll)
# Exact zone slab and two explicitly external connector tiles.
for x in range(-28,20,4):
 for y in range(-72,-48,4):inst(f'ServiceGround_{x}_{y}','floor',(x,y,0))
inst('SouthCrossingApproach','floor',(20,-52,0),coll=linkcoll)
# 32 x 20 m high-bay workshop; 4 m east mezzanine; 12 m building height.
for x in [2.25]:
 for y in [-71,-67,-63,-59,-55]:inst(f'MezzFloor_{x}_{y}','floor',(x,y,4))
for x in [-25.75,-21.75,-17.75,-13.75,-9.75,-5.75,-1.75,2.25]:
 for y in [-71,-67,-63,-59,-55]:inst(f'ServiceRoof_{x}_{y}','roof',(x,y,11.745),coll=roofcoll)
for z in [0,4,8]:
 for x in [-25.75,-21.75,-17.75,-13.75,-9.75,-5.75,-1.75,2.25]:
  inst(f'SouthWall_{x}_{z}','window_wall' if z>=4 else 'solid_wall',(x,-70.75,z))
  if z>=4 or x not in [-21.75,-17.75,-13.75,-9.75]:inst(f'NorthWall_{x}_{z}','window_wall' if z>=4 else ('door_wall' if x==2.25 else 'solid_wall'),(x,-51.25,z))
 for y in [-71,-67,-63,-59,-55]:
  inst(f'WestWall_{y}_{z}','window_wall' if z>=4 else 'solid_wall',(-25.75,y,z),90)
  k='door_wall' if (z==4 and y==-63) or (z==0 and y==-55) else ('window_wall' if z>=4 else 'solid_wall')
  inst(f'EastWall_{y}_{z}',k,(6.25,y,z),90)
for i,x in enumerate([-21.75,-13.75]):inst(f'NorthServiceBay_{i}','bay_wall',(x,-51.25,0))
# Mezzanine support and safe west edge, leaving a 2 m stair arrival opening.
for i,(x,y) in enumerate([(x,y) for x in [3.25,5.25] for y in [-69,-61,-53]]):inst(f'MezzColumn_{i}','column',(x,y,-.5));inst(f'MezzHead_{i}','column_head',(x,y,3.5))
inst('InteriorStairLower','stairs',(-5.75,-68,0));inst('InteriorStairUpper','stairs',(-1.75,-68,2))
inst('MezzRailShort','rail_infill',(2.25,-71,4),90)
for i,y in enumerate([-67,-63,-59,-55]):inst(f'MezzRail_{i}','rail_open',(2.25,y,4),90)
# Workshop furniture: two new racks reused, with actual pump and pipe assets as service stock.
for i,(x,y,z) in enumerate([(-24,-69.75,0),(-19,-69.75,0),(-14,-69.75,0),(-9,-69.75,0),(-24.75,-54,0)]):inst(f'StorageRack_{i}','rack',(x,y,z))
for i,x in enumerate([-23,-23]):inst(f'SparePump_{i}','pump',(x,-63+i*6,.5))
for i,x in enumerate([-16.5,-14.5]):inst(f'SparePipeSupport_{i}','pipe_support',(x,-63.5,0),90)
inst('SparePipe','pipe',(-17.5,-64,2))
# Elevated connection: branch, two flights up, six bridge segments, two flights down, service landing.
inst('PumpBranchWalk','straight',(22.25,-15,4),coll=linkcoll)
inst('PumpOuterCorner','corner',(29.25,-18,4),90,linkcoll)
inst('BridgeRiseLower','stairs',(29.25,-18,4),-90,linkcoll);inst('BridgeRiseUpper','stairs',(29.25,-22,6),-90,linkcoll)
for i,y in enumerate([-26,-30,-34,-38,-42,-46]):inst(f'HighBridge_{i}','straight',(29.25,y,8),-90,linkcoll)
inst('BridgeDescendUpper','stairs',(29.25,-54,6),90,linkcoll);inst('BridgeDescendLower','stairs',(29.25,-58,4),90,linkcoll)
inst('ServiceOuterCorner','corner',(26.25,-61,4),0,linkcoll)
for i,x in enumerate([22.25,18.25,14.25,10.25,6.25]):inst(f'ServiceLink_{i}','straight',(x,-61,4),0,linkcoll)
for i,(x,y) in enumerate([(24.5,-15),(29.25,-17),(29.25,-58),(25.25,-61),(21.25,-61),(17.25,-61),(13.25,-61),(9.25,-61)]):inst(f'LinkLowColumn_{i}','column',(x,y,-.2),coll=linkcoll)
for i,y in enumerate([-26,-34,-38,-50]):
 for j,x in enumerate([28.5,30]):
  inst(f'BridgePierLower_{i}_{j}','column',(x,y,-.7),coll=linkcoll);inst(f'BridgePierUpper_{i}_{j}','column',(x,y,3.3),coll=linkcoll)
# Perimeter-only supports and long-span roof trusses leave the production floor free of internal columns.
for i,y in enumerate([-69,-65,-57,-53]):
 inst(f'HallRoofTruss_{i}','roof_truss',(-25.75,y,9.495))
 for j,x in enumerate([-25.5,6]):
  for k,z in enumerate([-.255,3.745,7.745]):inst(f'HallPerimeterColumn_{i}_{j}_{k}','column',(x,y,z))
# Context parts are identified separately: plinths, structural bearing beams, paint and flush approach ramp.
def material(n,c,metal=0):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.65;p.inputs['Metallic'].default_value=metal;return m
concrete=material('B04_ContextConcrete',(.24,.30,.32));yellow=material('B04_PaintYellow',(.88,.54,.055));white=material('B04_PaintWhite',(.8,.86,.86));steel=material('B04_BearingSteel',(.08,.12,.14),.7)
def move(o,c):
 for cc in list(o.users_collection):cc.objects.unlink(o)
 c.objects.link(o)
def box(n,c,d,m,coll=zone,bevel=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);o=bpy.context.object;o.name='CONTEXT_'+n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);move(o,coll)
 if bevel:b=o.modifiers.new('fabricated edges','BEVEL');b.width=bevel;b.segments=2
 return o
def text(n,t,loc,size,rot=(0,0,0)):
 bpy.ops.object.text_add(location=loc,rotation=rot);o=bpy.context.object;o.name='LABEL_'+n;o.data.body=t;o.data.size=size;o.data.extrude=.001;o.data.materials.append(white);move(o,zone);return o
for i,x in enumerate([-23,-23]):box(f'ServiceSkidPlinth_{i}',(x+2,-63+i*6,.25),(4,2,.5),concrete)
box('InteriorStairPier',(-1.75,-68,.9),(.5,2,1.8),concrete)
for x,y in [(29.25,-22),(29.25,-54)]:
 box(f'MidLandingPedestal_{y}',(x,y,.9),(1.2,1.2,1.8),concrete,linkcoll);inst(f'MidLandingColumn_{y}','column',(x,y,1.8),coll=linkcoll)
# Continuous 12 m I girders keep the crossing physically supported. Their underside sets measured clearance.
for x in [28.5,30]:
 for z in [7.325,7.775]:box(f'RoadGirderFlange_{x}_{z}',(x,-44,z),(.22,12,.05),steel,linkcoll)
 box(f'RoadGirderWeb_{x}',(x,-44,7.55),(.06,12,.4),steel,linkcoll)
for y in [-26,-34,-38,-50]:box(f'BridgeBearing_{y}',(29.25,y,7.55),(2.25,.3,.5),steel,linkcoll)
for x in [-25.5,-21.75,-17.75,-13.75,-9.75,-5.75,-1.75,2.25,6]:box(f'RoofPurlin_{x}',(x,-61,11.62),(.20,20,.25),steel)
asphalt=material('B04_LocalRoadAsphalt',(.07,.09,.10))
localroad=box('LocalRoad', (4,-44,-.04),(64,8,.22),asphalt,linkcoll,0)
# 3 m deep loading approach, 12 m wide court, high-visibility ground crossing at road height.
for y in [-70,-66,-62,-58,-54]:box(f'CourtDash_{y}',(18,y,.006),(.10,2,.012),yellow)
for y in [-47.5,-46.5,-45.5,-44.5,-43.5,-42.5,-41.5,-40.5]:box(f'RoadCrossingStripe_{y}',(22,y,.078),(3.5,.45,.016),white,linkcoll,0)
for x in [-17.75,-9.75]:
 for side in [-3,3]:box(f'BayLane_{x}_{side}',(x+side,-55,.008),(.08,7,.016),yellow)
text('ServiceArea','07 / SERVICE + SPARES',(8,-70,.025),.6,(0,0,math.pi/2));text('Mezzanine','MAINTENANCE ACCESS',(.5,-60,4.025),.28,(0,0,math.pi/2))
for i,x in enumerate([-17.75,-9.75]):text('Bay_'+str(i),'BAY 0'+str(i+1),(x-1.1,-51.411,3.55),.30,(math.pi/2,0,0))
# South threshold to original road Z=.07; the north threshold remains from Batch03.
me=bpy.data.meshes.new('SouthThresholdRamp');me.from_pydata([(20,-48,.07),(24,-48,.07),(24,-49,0),(20,-49,0),(20,-48,-.1),(24,-48,-.1),(24,-49,-.1),(20,-49,-.1)],[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);o=bpy.data.objects.new('CONTEXT_SouthRoadThreshold',me);linkcoll.objects.link(o);me.materials.append(concrete)
# Exact connectivity: actual transformed sockets, including preserved pump north/south ports.
def socket(key,tag):
 k,o=instances[key];sc=next(p for p in specs[k]['connection_sockets'] if p['id']==tag);return o.matrix_world@Vector(sc['position_m']),o.matrix_world.to_3x3()@Vector(sc['outward_normal'])
links=[('PUMP__EastWalk_0','start','PumpLinkTee','start'),('PumpLinkTee','end','PUMP__StairUpper','upper'),('PumpLinkTee','branch','PumpBranchWalk','start'),('PumpBranchWalk','end','PumpOuterCorner','turn'),('PumpOuterCorner','start','BridgeRiseLower','lower'),('BridgeRiseLower','upper','BridgeRiseUpper','lower'),('BridgeRiseUpper','upper','HighBridge_0','start')]
links += [(f'HighBridge_{i}','end',f'HighBridge_{i+1}','start') for i in range(5)]
links += [('HighBridge_5','end','BridgeDescendUpper','upper'),('BridgeDescendUpper','lower','BridgeDescendLower','upper'),('BridgeDescendLower','lower','ServiceOuterCorner','turn'),('ServiceOuterCorner','start','ServiceLink_0','end')]
links += [(f'ServiceLink_{i}','start',f'ServiceLink_{i+1}','end') for i in range(4)]
links += [('ServiceLink_4','start','EastWall_-63_4','passage'),('InteriorStairLower','upper','InteriorStairUpper','lower')]
checks=[]
for a,aa,b,bb in links:
 pa,na=socket(a,aa);pb,nb=socket(b,bb);gap=(pa-pb).length;dot=na.dot(nb);checks.append({'test':'actual transformed sockets','connection':[a,aa,b,bb],'gap_m':gap,'normals_dot':dot,'status':'PASS' if gap<1e-5 and dot<-.9999 else 'FAIL'})
# Revised 07 envelope excludes connector works. Roof extends to 11.995 m.
vv=[o.matrix_world@v.co for coll in [zone,roofcoll] for o in coll.objects if o.type=='MESH' and o.get('asset_id') for v in o.data.vertices];mn=[min(v[a] for v in vv) for a in range(3)];mx=[max(v[a] for v in vv) for a in range(3)]
checks.append({'test':'revised 07 envelope, height raised from 8 to 12 m','min_m':mn,'max_m':mx,'status':'PASS' if mn[0]>=-28.0001 and mn[1]>=-72.0001 and mx[0]<=20.0001 and mx[1]<=-47.9999 and mx[2]<=12.0001 else 'FAIL'})
# Road clearance measured against every mesh in connector collection whose XY bounds intersects the crossing prism.
under=[]
for o in linkcoll.objects:
 if o.type!='MESH' or 'RoadCrossingStripe' in o.name or 'Threshold' in o.name or 'LocalRoad' in o.name:continue
 vs=[o.matrix_world@v.co for v in o.data.vertices];lo=[min(v[a] for v in vs) for a in range(3)];hi=[max(v[a] for v in vs) for a in range(3)]
 if hi[0]>28.25 and lo[0]<30.25 and hi[1]>-48+1e-5 and lo[1]<-40-1e-5:under.append((o.name,lo[2]))
minimum=min(v for n,v in under);checks.append({'test':'bridge crossing measured vertical clearance','road_top_z':.07,'lowest_bridge_z':minimum,'clearance_m':minimum-.07,'objects':under,'status':'PASS' if minimum-.07>7.2 else 'FAIL'})
report={'status':'PASS' if all(c['status']=='PASS' for c in checks) else 'FAIL','checks':checks,'module_instance_count':len(instances),'pump_instance_count':sum(k.startswith('PUMP__') for k in instances),'new_zone_and_connector_instances':sum(not k.startswith('PUMP__') for k in instances),'new_assets':3,'copy_modification':'One pump straight walkway replaced by T-junction in this scene only; original ground stair remains connected.','limits':['Actual geometry and socket validation, not UE traversal.','Bridge beams are appearance plausibility, not structural certification.','Six zones remain original grayboxes. Service envelope height is explicitly revised from 8 to 12 m.']}
(R/'Validation/region_validation.json').write_text(json.dumps(report,indent=2));(R/'Region/placements.json').write_text(json.dumps({'units':'meters','axis':'Blender Z up','lineage':lineage,'placements':[{'instance':k,'asset_id':specs[t]['asset_id'],'matrix_world':[list(row) for row in o.matrix_world]} for k,(t,o) in instances.items()]},indent=2))
# 6 m clear main aisle, kept free of equipment. Storage and pump work bays occupy the west perimeter.
for x in [-12,-6]:box(f'MainAisleBoundary_{x}',(x,-59.5,.008),(.08,15,.016),yellow)
text('MainAisle','6 m / MAIN AISLE',(-11.4,-66,.025),.38,(0,0,math.pi/2))
# 1.8 m mannequins and a true 0.6 m diameter by 1.8 m capsule: review-only scale collection.
scale=bpy.data.collections.new('SCALE_REFERENCES_TOGGLE');s.collection.children.link(scale)
orange=material('ScaleReferenceOrange',(.95,.22,.045));cyan=material('ScaleCapsuleCyan',(.04,.65,.75))
def sphere(name,c,sc,mat):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=c);o=bpy.context.object;o.name=name;o.scale=sc;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);move(o,scale);return o
def limb(name,a,b,r):
 a=Vector(a);b=Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(orange);move(o,scale)
def mannequin(i,x,y,z):
 sphere(f'HUMAN_{i}_Head',(x,y,z+1.68),(.12,.12,.12),orange);sphere(f'HUMAN_{i}_Torso',(x,y,z+1.30),(.20,.12,.28),orange);sphere(f'HUMAN_{i}_Pelvis',(x,y,z+.96),(.18,.12,.16),orange)
 for sign in [-1,1]:
  limb(f'HUMAN_{i}_Leg_{sign}',(x+sign*.10,y,z+.12),(x+sign*.10,y,z+.94),.065)
  foot=box(f'HUMAN_{i}_Foot_{sign}',(x+sign*.10,y-.05,z+.05),(.12,.25,.10),orange,scale)
  limb(f'HUMAN_{i}_Arm_{sign}',(x+sign*.23,y,z+1.49),(x+sign*.29,y,z+.92),.045)
for i,xyz in enumerate([(-17,-54,0),(-10,-65,0),(-2,-60,0),(4,-58,4)]):mannequin(i,*xyz)
# Build capsule as one cylinder plus true hemispheres; the overlaps are reference-only, never exported collision.
bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.3,depth=1.2,location=(-15,-60,.9));o=bpy.context.object;o.name='CAPSULE_0.6m_diameter_1.8m_height';o.data.materials.append(cyan);move(o,scale)
sphere('CAPSULE_Lower',(-15,-60,.3),(.3,.3,.3),cyan);sphere('CAPSULE_Upper',(-15,-60,1.5),(.3,.3,.3),cyan)
# High-bay area lights below the roof; fixtures remain above the lowest truss chord.
lightmat=material('HighBayLuminaire',(.85,.92,.95));bs=lightmat.node_tree.nodes['Principled BSDF'];bs.inputs['Emission Color'].default_value=(.8,.9,1,1);bs.inputs['Emission Strength'].default_value=1
for x in [-18,-6]:
 for y in [-67,-61,-55]:
  box(f'HighBayLightFixture_{x}_{y}',(x,y,10),(3,.25,.1),lightmat)
  bpy.ops.object.light_add(type='AREA',location=(x,y,9.9));l=bpy.context.object;l.name=f'HALL_LIGHT_{x}_{y}';l.data.energy=1400;l.data.size=4
# Lighting and cameras.
for name,loc,energy,size in [('KEY',(-15,-35,75),60000,50),('FILL',(55,-55,40),28000,35),('RIM',(-35,-100,45),38000,35)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=energy;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((3,-38,2))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;cam.name='ConnectedDistricts_Beauty_ORTHO';cam.data.type='ORTHO';s.camera=cam

def camera(loc,target,scale,res=(2000,1600)):
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;s.render.resolution_x=res[0];s.render.resolution_y=res[1]
def render(n):
 if RENDER:s.render.filepath=str(R/'Previews'/n);bpy.ops.render.render(write_still=True)
camera((100,28,80),(2,-38,4),97)
# Bundle mesh data into four local geometry libraries so every ordinary ZIP stays below 8 MB.
# The complete extracted package is self-contained; opening the scene resolves relative links automatically.
geom=R/'Geometry';geom.mkdir(exist_ok=True)
moduleobjects=[o for o in s.objects if o.type=='MESH' and o.get('asset_id')]
meshes=sorted({o.data for o in moduleobjects},key=lambda m:len(m.loops),reverse=True);groups=[[] for _ in range(4)];weights=[0]*4
for m in meshes:
 j=min(range(4),key=lambda i:weights[i]);groups[j].append(m);weights[j]+=len(m.loops)
libinfo=[]
for i,group in enumerate(groups):
 path=geom/f'kit_geometry_{i+1:02d}.blend';bpy.data.libraries.write(str(path),set(group),fake_user=True,compress=False)
 with bpy.data.libraries.load(str(path),link=True) as (a,b):b.meshes=[m.name for m in group]
 replacement=dict(zip(group,b.meshes))
 for ob in moduleobjects:
  if ob.data in replacement:ob.data=replacement[ob.data]
 libinfo.append({'path':str(path.relative_to(R)),'meshes':[m.name for m in group],'loop_weight':weights[i]})
for lib in bpy.data.libraries:lib.filepath=bpy.path.relpath(lib.filepath,start=str(R/'Region'))
(R/'Geometry/asset_mesh_map.json').write_text(json.dumps([{'asset_id':o['asset_id'],'mesh':o.data.name,'library':o.data.library.filepath} for o in moduleobjects],indent=2))
(R/'Geometry/libraries.json').write_text(json.dumps({'relative_link_base':'Region/*.blend','libraries':libinfo,'instruction':'Extract every ZIP part to the same parent directory. Keep Geometry alongside Region; Blender resolves links automatically.'},indent=2))
bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
for lib in bpy.data.libraries:lib.filepath='//../Geometry/'+pathlib.Path(lib.filepath).name
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region/pump_service_connected.blend'),compress=False,relative_remap=False)
render('pump_service_connected.png')
camera((1,-38,100),(1,-38,0),91,(1600,1800));render('connected_top.png')
# Explicit cutaway visualization; default saved source retains every roof and facade.
roofcoll.hide_render=True;hidden=[]
for o in zone.objects:
 if o.name.startswith('NorthWall_') and (o.name.endswith('_4') or o.name.endswith('_8')):o.hide_render=True;hidden.append(o)
camera((43,-20,42),(-7,-61,4),50,(1900,1400));render('service_cutaway.png')
roofcoll.hide_render=False
for o in hidden:o.hide_render=False
camera((58,-25,25),(28,-43,5),36,(1800,1400));render('bridge_connection_detail.png')
# Genuine perspective eye-height views; no orthographic projection or miniature-camera framing.
cam.data.type='PERSP';cam.data.lens=24;cam.data.clip_start=.05
cam.location=(-9,-52.5,1.65);cam.rotation_euler=(Vector((-11,-67,3.4))-cam.location).to_track_quat('-Z','Y').to_euler();s.render.resolution_x=1920;s.render.resolution_y=1280;s.cycles.samples=96;render('hall_eye_height_1p65m.png')
cam.location=(-23.5,-68.5,1.65);cam.rotation_euler=(Vector((1,-55,4.0))-cam.location).to_track_quat('-Z','Y').to_euler();render('hall_eye_across_span.png')
cam.data.type='ORTHO';s.cycles.samples=48
bpy.data.objects.remove(localroad,do_unlink=True)
# Reuse the already-recessed Batch03 site context, remove only 07 box and label.
with bpy.data.libraries.load(str(F/'Batch03/Region/site_with_pump_zone.blend'),link=False) as (a,b):b.collections=['OTHER_7_ZONES_GRAYBOX']
context=b.collections[0];s.collection.children.link(context);context.name='OTHER_6_ZONES_GRAYBOX'
for n in ['07_SERVICE','Label_07_SERVICE']:
 for o in list(context.objects):
  if o.name==n:bpy.data.objects.remove(o,do_unlink=True)
ground=next(o for o in context.objects if o.name.startswith('SITE_224x192'))
for x0,x1,y0,y1 in [(-28,20,-72,-48),(20,24,-52,-48)]:
 bpy.ops.mesh.primitive_cube_add(size=1,location=((x0+x1)/2,(y0+y1)/2,.37));cut=bpy.context.object;cut.dimensions=(x1-x0,y1-y0,1.26);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);bpy.context.view_layer.objects.active=ground;mod=ground.modifiers.new('Batch04 recess under slabs','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
ground['batch04_recess_m']=.26
camera((160,-215,185),(0,0,5),270,(1800,1400));s.cycles.samples=48
bpy.ops.object.light_add(type='AREA',location=(-60,-80,160));o=bpy.context.object;o.name='SITE_KEY';o.data.energy=200000;o.data.size=150
bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
for lib in bpy.data.libraries:lib.filepath='//../Geometry/'+pathlib.Path(lib.filepath).name
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region/site_with_pump_service.blend'),compress=False,relative_remap=False);render('site_with_pump_service.png')
print('BATCH04_REGION_COMPLETE',report['status'],len(instances),len(checks),flush=True)
