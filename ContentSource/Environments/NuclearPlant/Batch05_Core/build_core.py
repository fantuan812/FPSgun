import bpy, math, json, sys, pathlib, importlib.util
from mathutils import Vector, Matrix
R=pathlib.Path(__file__).resolve().parent
CFG=json.loads((R/'core_config.json').read_text())
EXPECTED={'hall_width':40,'hall_depth':36,'hall_height':20,'reactor_center':[0,0,0],'platform_z':4.5,'upper_platform_z':10,'gallery_width':3,'stair_steps':25,'stair_rise':4.5,'stair_run':7,'stair_width':2.4}
if CFG['structure_template'] != EXPECTED: raise ValueError('Unsupported structure template change; edit topology generator and validate before changing dimensions.')
(R/'renders').mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
s.render.engine='CYCLES';s.cycles.samples=32;s.cycles.use_denoising=False;s.cycles.max_bounces=5
s.render.resolution_x=1600;s.render.resolution_y=1000;s.render.resolution_percentage=100
s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('Overcast daylight');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.52,.65,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.25
COL={}
def coll(n):
 c=bpy.data.collections.new(n);s.collection.children.link(c);COL[n]=c;return c
architecture=coll('01_Hall_Architecture');roof=coll('02_Roof_Toggle');walk=coll('03_Circulation');services=coll('04_Functional_Services');outside=coll('05_Entry_Court');details=coll('06_Signage_Lights');people=coll('07_Scale_1p8m');lighting=coll('08_Lighting_Cameras')
def move(o,c):
 for cc in list(o.users_collection):cc.objects.unlink(o)
 c.objects.link(o);return o
def material(n,color,metal=0,rough=.6,noise=False,emission=0):
 color=tuple(CFG.get('palette',{}).get(n,color));m=bpy.data.materials.new(n);m.diffuse_color=(*color,1);m.use_nodes=True;nd=m.node_tree.nodes;bs=nd.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
 if noise:
  tex=nd.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=5;tex.inputs['Detail'].default_value=3
  ramp=nd.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=tuple(v*.7 for v in color)+(1,);ramp.color_ramp.elements[1].color=tuple(min(v*1.2,1) for v in color)+(1,);m.node_tree.links.new(tex.outputs['Fac'],ramp.inputs[0]);m.node_tree.links.new(ramp.outputs['Color'],bs.inputs['Base Color'])
  bump=nd.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.04;m.node_tree.links.new(tex.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs[0],bs.inputs['Normal'])
 if emission:bs.inputs['Emission Color'].default_value=(*color,1);bs.inputs['Emission Strength'].default_value=emission
 return m
concrete=material('Pale cast concrete',(.49,.52,.53),noise=True);floor=material('Sealed aggregate floor',(.25,.29,.31),rough=.42,noise=True);steel=material('Graphite structure',(.055,.075,.085),.75,.34);red=material('Oxide red panels',(.36,.035,.024),.35,.43,True);silver=material('Brushed pipe stainless',(.38,.44,.48),.85,.27);yellow=material('Safety ochre',(.88,.52,.055),.15);white=material('Offwhite wayfinding',(.81,.85,.84));black=material('Shadow line',(.012,.018,.023));glass=material('Blue glazing',(.10,.23,.29),.65,.18);warm=material('Warm fixture',(.95,.64,.30),emission=4);cool=material('Cool fixture',(.56,.78,.92),emission=4);asphalt=material('Court asphalt',(.075,.09,.10),noise=True);soil=material('Damp gravel',(.11,.13,.11),noise=True);leaf=material('Low scrub',(.095,.14,.065),rough=.85)
def box(n,loc,dims,mat,c=architecture,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dims;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);move(o,c)
 if bevel:b=o.modifiers.new('Edge highlight','BEVEL');b.width=bevel;b.segments=2
 return o
def cyl(n,loc,r,depth,mat,c=services,vertices=48):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc);o=bpy.context.object;o.name=n;o.data.materials.append(mat);move(o,c)
 b=o.modifiers.new('Machined edge','BEVEL');b.width=.025;b.segments=2
 for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
 return o
def beam(n,a,b,width,mat,c=architecture,depth=None):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(width,depth or width,(b-a).length),mat,c,.01);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def pipe(n,pts,r,mat=silver,c=services):
 cv=bpy.data.curves.new(n,'CURVE');cv.dimensions='3D';cv.resolution_u=12;cv.bevel_depth=r;cv.bevel_resolution=3;sp=cv.splines.new('POLY');sp.points.add(len(pts)-1)
 for p,co in zip(sp.points,pts):p.co=(*co,1)
 o=bpy.data.objects.new(n,cv);c.objects.link(o);cv.materials.append(mat);return o
def text(n,t,loc,size,rot=(math.pi/2,0,0),mat=white,c=details):
 cv=bpy.data.curves.new(n,'FONT');cv.body=t;cv.size=size;cv.extrude=.001;cv.align_x='CENTER';o=bpy.data.objects.new(n,cv);c.objects.link(o);o.location=loc;o.rotation_euler=rot;cv.materials.append(mat);return o
def rail(n,a,b,z,c=walk,panels=False):
 a,b=Vector((a[0],a[1],z)),Vector((b[0],b[1],z));length=(b-a).length
 for i in range(math.ceil(length/2)+1):
  p=a+(b-a)*i/math.ceil(length/2);beam(n+'_post',p,p+Vector((0,0,1.1)),.055,steel,c)
 for h in [.1,.56,1.1]:beam(n+'_bar',a+Vector((0,0,h)),b+Vector((0,0,h)),.055,red if h==1.1 else steel,c)
 if panels:
  count=max(1,int(length/2.4))
  for i in range(count):
   p=a+(b-a)*(i+.5)/count+Vector((0,0,.55));o=box(n+'_red_panel',p,(length/count-.18,.055,.62),red,c,.01);o.rotation_euler.z=math.atan2(b.y-a.y,b.x-a.x)
def area(n,loc,target,power,size,color=(.78,.87,1)):
 d=bpy.data.lights.new(n,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(n,d);lighting.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();return o
# Floor large slabs, enough pattern to communicate real scale.
box('Foundation',(0,0,-.35),(41,37,.7),concrete)
for x in range(-18,20,4):
 for y in range(-16,18,4):box('Floor panel',(x,y,-.055),(3.975,3.975,.1),floor,architecture,.008)
# Architectural wall panels. Red equipment band, pale concrete above, dark construction joints.
for side in [-1,1]:
 for y in range(-16,18,4):
  for z in [2,6,10,14,18]:box('Side concrete panel',(side*20,y,z),(.5,3.97,3.97),red if z==2 else concrete)
 for y in [-16,-8,0,8,16]:
  box('Wall pilaster',(side*19.6,y,9.5),(.55,.65,19),steel)
  box('Pilaster shoe',(side*19.6,y,.3),(.9,1,.6),concrete)
for y in [-18,18]:
 for x in range(-18,20,4):
  for z in [2,6,10,14,18]:
   if y<0 and abs(x)<4 and z<8:continue
   box('End wall panel',(x,y,z),(3.97,.5,3.97),red if z==2 else concrete)
# Entry portal is 8m wide x8m high, real void, oversized sliding leaves parked to sides.
for x in [-4.3,4.3]:box('Portal jamb',(x,-18.1,4),(.6,1,8),steel)
box('Portal lintel',(0,-18.1,8.3),(9.2,1,.6),steel)
for side in [-1,1]:
 box('Open sliding leaf',(side*6.45,-18.65,3.5),(3.8,.18,7),red)
 for z in [1,2,3,4,5,6]:box('Door stiffener',(side*6.45,-18.78,z),(3.6,.08,.08),steel)
text('Main hall number','R  /  01',(0,-18.38,10),2)
text('Entry identity','REACTOR SERVICE HALL',(0,-18.4,9),.43)
# Back control room window wall under gallery, panes not random panels.
for x in [-12,-8,8,12]:
 box('Control room window frame',(x,17.65,2.25),(3.6,.18,1.8),steel)
 box('Control room glazing',(x,17.53,2.25),(3.35,.04,1.55),glass)
 box('Window mullion',(x,17.47,2.25),(.055,.08,1.6),silver)
text('Rear zone','02  /  CONTROL',(0,17.65,2),.8,(math.pi/2,0,math.pi))
# Side galleries at 4.5 m surface. Leave bridge and stair landing openings.
for side in [-1,1]:
 box('Side service gallery',(side*17,1,4.33),(3,32,.34),steel,walk)
 for y in [-4,4,12]:
  box('Gallery pillar',(side*17.8,y,2.1),(.25,.3,4.2),steel,walk)
  beam('Gallery brace',(side*19,y,2.4),(side*15.5,y,4.1),.14,steel,walk)
 rail('Inner side guard A',(side*15.5,-8),(side*15.5,-1.7),4.5,panels=True)
 rail('Inner side guard B',(side*15.5,1.7),(side*15.5,13),4.5,panels=True)
 # radial bridge meets annular reactor platform at y +/-1.5; extend to r=6.8 ensures no crescent gap.
 box('Radial access bridge',(side*11.15,0,4.33),(8.7,3,.34),steel,walk)
 for y in [-1.5,1.5]:rail('Bridge guard',(side*6.8,y),(side*15.5,y),4.5,panels=True)
 for y in [-1.35,1.35]:beam('Bridge bearing',(side*6.8,y,4.05),(side*15.5,y,4.05),.18,steel,walk,.3)
 # Stair 25 x 180 mm rises. Run 7m along +Y, width2.4.
 sx=side*17;sy=-15
 for i in range(25):
  top=(i+1)*.18;box('Stair tread',(sx,sy+(i+.5)*.28,top-.035),(2.4,.28,.07),silver,walk,.008)
  box('Tread yellow nosing',(sx,sy+i*.28+.025,top+.005),(2.35,.035,.01),yellow,walk,0)
 for dx in [-1.25,1.25]:
  beam('Stair stringer',(sx+dx,sy,-.12),(sx+dx,sy+7,4.38),.15,steel,walk,.24)
  beam('Stair handrail',(sx+dx,sy,1.1),(sx+dx,sy+7,5.6),.06,red,walk)
  for j in range(6):
   yy=sy+7*j/5;zz=4.5*j/5;beam('Stair post',(sx+dx,yy,zz),(sx+dx,yy,zz+1.1),.05,steel,walk)
 # gallery slab must not overlap stair overhead: cut actual stair bay out below y-8.
 # Existing full side slab starts -15; replace front stair segment by side shoulder strips.
 ob=next(o for o in walk.objects if o.name.startswith('Side service gallery') and o.location.x==side*17)
 ob.location.y=4.5;ob.dimensions.y=25 # extends -8 to17, no low headspace above stair
 rail('Stair outer gallery edge',(side*18.5,-8),(side*18.5,17),4.5)
box('Rear gallery',(0,15.5,4.33),(31,3,.34),steel,walk)
rail('Rear gallery guard',(-15.5,14),(15.5,14),4.5,panels=True)
# Rear gallery structural rhythm, ceiling deep trusses at z18 and roof at20.
for y in [-12,-4,4,12]:
 for z in [18,19.65]:beam('Roof truss chord',(-19.5,y,z),(19.5,y,z),.22,steel,roof,.32)
 for i in range(10):
  x=-19.5+i*3.9;beam('Roof truss diagonal',(x,y,18),(x+3.9,y,19.65),.13,steel,roof)
  beam('Roof truss web',(x,y,18),(x,y,19.65),.12,steel,roof)
for x in [-18,-14,-10,-6,-2,2,6,10,14,18]:beam('Roof purlin',(x,-18,19.8),(x,18,19.8),.13,steel,roof,.22)
# Roof covers hall; daylight strip glazing does not remove whole roof.
for x,w in [(-17,6),(-9,6),(0,8),(9,6),(17,6)]:box('Roof opaque sandwich',(x,0,20.1),(w,36,.2),concrete,roof)
for x in [-13,-5,5,13]:
 box('Skylight strip',(x,0,20.13),(1.7,36,.12),glass,roof)
 for y in range(-16,18,4):box('Skylight cross frame',(x,y,20.25),(1.8,.1,.14),steel,roof)
# Lighting fixture boxes and real light sources below roof.
for x in [-12,12]:
 for y in [-12,-4,4,12]:
  box('Suspended luminaire',(x,y,15.6),(2.8,.45,.16),steel,details)
  box('Luminaire diffuser',(x,y,15.5),(2.6,.38,.03),cool,details,.005)
  beam('Fixture suspension',(x,y,15.7),(x,y,18),.025,steel,details)
  area('Highbay luminaire',(x,y,15.4),(x,y,0),1800,4)
for side in [-1,1]:
 for y in [-4,7]:
  box('Under gallery linear',(side*17,y,4.05),(.2,4,.06),cool,details)
  area('Gallery pool',(side*16,y,3.9),(side*14,y,0),350,3)
# Functional pipe trunks anchored along side bands, giving a deliberate service gradient.
for side in [-1,1]:
 for z in [7,8.15]:
  pipe('Wall coolant trunk',[(side*18.7,-16,z),(side*18.7,16,z)],.27)
  for y in [-12,-4,4,12]:
   # flange across Y
   o=cyl('Coolant coupling',(side*18.7,y,z),.35,.16,steel);o.rotation_euler.x=math.pi/2
   beam('Pipe bracket',(side*19.5,y,z-.6),(side*18.3,y,z-.6),.09,steel)
 # large pipe elbow polygon arc with bevel geometry, connects rear service to reactor side.
 pts=[(side*18.7,8,7),(side*15,8,7),(side*12,8,7),(side*11,7.6,7),(side*10.5,6.8,7),(side*10.5,4.5,7),(side*9.5,3.5,7),(side*6,3.5,7)]
 pipe('Primary coolant route',pts,.5)
 for x,y in [(side*13,8),(side*10.5,5.5)]:
  box('Coolant support plinth',(x,y,.2),(1.5,1.5,.4),concrete,services)
  beam('Coolant support leg',(x,y,.4),(x,y,6.4),.22,steel,services)
# Floor painted circulation, central entry path and working zones. No random debris scatter.
for x in [-3.2,3.2]:box('Entry clear aisle edge',(x,-12.5,.015),(.09,9,.02),yellow,details,0)
for y in [-13.8,-12.8,-11.8]:
 for side in [-1,1]:
  o=box('Directional arrow stroke',(side*.2,y,.018),(.08,.6,.025),white,details,0);o.rotation_euler.z=side*.65
text('Floor entry designation','01 / CORE',(-5.8,-13,.02),.65,(0,0,math.pi/2),white)
for side in [-1,1]:
 for y in [-4,4]:
  text('Wall bay number',('A' if side<0 else 'B')+'0'+str(1 if y<0 else 2),(side*19.68,y,5.8),1.1,(math.pi/2,0,side*math.pi/2))
# External entrance composition: hardstand, canopy, planted boundary, pipe/service wing.
box('Entry approach',(0,-26,-.13),(30,16,.25),asphalt,outside)
for side in [-1,1]:
 box('Entry curb',(side*15,-26,.13),(.3,16,.25),concrete,outside)
 box('Gravel planting edge',(side*18,-25,-.02),(5,14,.12),soil,outside)
 for y in [-31,-26,-21]:
  for off in [-.7,.7]:
   bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(side*18+off,y,.6));o=bpy.context.object;o.name='Boundary scrub';o.scale=(.9,1.2,.8);o.data.materials.append(leaf);move(o,outside)
 for y in [-24,-20]:
  cyl('Vehicle bollard',(side*5,y,.55),.14,1.1,steel,outside,20)
  cyl('Bollard reflective band',(side*5,y,.85),.145,.15,yellow,outside,20)
 # service wing compact mass but attached; not competing landmark
 box('External service wing',(side*25,5,4),(10,24,8),concrete,outside)
 for y in [-5,1,7,13]:
  box('Service wing louvre frame',(side*30.05,y,4),(.12,4,3),steel,outside)
  for z in [2.7,3.2,3.7,4.2,4.7,5.2]:box('Wing ventilation louvre',(side*30.15,y,z),(.2,3.8,.12),silver,outside)
box('Entrance canopy',(0,-20,7.9),(12,4,.3),steel,outside)
for x in [-5.5,5.5]:beam('Canopy support',(x,-21.8,0),(x,-21.8,7.8),.18,steel,outside)
for y in [-32,-29,-26]:box('Court lane dash',(0,y,.012),(.12,1.5,.02),white,outside,0)
# Reuse actual Batch04 asset mesh: pumps, pipe supports and maintenance rack. Append once then independent copies.
SOURCE=R/'Reused/batch04_reuse.blend'
if not SOURCE.exists():raise FileNotFoundError('Missing packaged Reused/batch04_reuse.blend')
if SOURCE.exists():
 with bpy.data.libraries.load(str(SOURCE),link=False) as (a,b):b.objects=['REUSED_B04_Pump_0_0','REUSED_B04_InletSupport_0_0','REUSED_B04_StorageRack_0_0']
 for src in b.objects:
  if not src:continue
  if src.data.library:src.data=src.data.copy()
  if 'Pump_0' in src.name:
   placements=[(-12,9,0),(8,10,0)]
  elif 'StorageRack' in src.name:placements=[(-18,10,0)]
  else:placements=[(-14,7,0),(12,7,0)]
  for i,p in enumerate(placements):
   o=src.copy();o.data=src.data;services.objects.link(o);o.location=p;o.rotation_euler=(0,0,0);o.name=src.name.rsplit('_',1)[0]+'_'+str(i);o['source_batch']='Batch04_LargeSpace verified delivery'
print('CORE STRUCTURE AND REUSE READY',flush=True)
# Fresh assets.
def module(path,name):
 spec=importlib.util.spec_from_file_location(name,str(path));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
if (R/'reactor/reactor_asset.py').exists():
 with bpy.data.libraries.load(str(R/'reactor/reactor.blend'),link=False) as (a,b):b.collections=['Reactor_Core']
 s.collection.children.link(b.collections[0])
else:
 cyl('TEMP_REACTOR_NOT_FINAL',(0,0,7),4,14,steel)
# Append reusable prop collections and instance at deliberate functional positions.
propfile=R/'props/props.blend'
if propfile.exists():
 with bpy.data.libraries.load(str(propfile),link=False) as (a,b):b.collections=['CP_ReactorConsole','CP_ElectricalCabinetBank','CP_VerticalServiceTank']
 templates={c.name:c for c in b.collections if c}
 placements=CFG['equipment_placements']
 for name,poses in placements.items():
  for i,(x,y,z,deg) in enumerate(poses):
   ob=bpy.data.objects.new(name+'_Placed_'+str(i),None);ob.instance_type='COLLECTION';ob.instance_collection=templates[name];services.objects.link(ob);ob.location=(x,y,z);ob.rotation_euler.z=math.radians(deg)

print('CORE ASSETS APPENDED',flush=True)
# Scale mannequins 1.80m, clearly non-gameplay reference.
def human(n,x,y,z):
 def ball(n,p,sc):
  bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=p);o=bpy.context.object;o.name=n;o.scale=sc;o.data.materials.append(yellow);move(o,people)
 ball(n+' head',(x,y,z+1.68),(.12,.12,.12));ball(n+' torso',(x,y,z+1.3),(.20,.12,.28));ball(n+' pelvis',(x,y,z+.98),(.18,.12,.14))
 for sg in [-1,1]:
  beam(n+' leg',(x+sg*.1,y,z+.12),(x+sg*.1,y,z+.98),.1,yellow,people)
  beam(n+' arm',(x+sg*.22,y,z+1.48),(x+sg*.28,y,z+.95),.075,yellow,people)
  box(n+' boot',(x+sg*.1,y-.05,z+.055),(.12,.25,.11),steel,people)
for i,p in enumerate([(-4,-10,0),(10,-5,0),(17,7,4.5)]):human('Scale_1p80_'+str(i),*p)
# Soft cinematic daylight; fixtures remain grounded in visible lighting.
area('Front daylight',(0,-24,13),(0,0,5),5500,12,(.75,.85,1))
area('Skylight wash',(0,-1,19.5),(0,0,4),6500,15,(.8,.87,1))
area('Rear warm separation',(2,14,13),(0,0,7),3200,8,(1,.67,.42))
area('Exterior sky key',(-20,-30,35),(0,-10,4),17000,25,(.82,.9,1))
area('Reactor side soft',(12,-5,8),(0,0,7),1500,7,(.65,.83,1))
cameras={}
def camera(n,loc,target,lens=30):
 d=bpy.data.cameras.new(n);d.lens=lens;d.clip_end=1000;o=bpy.data.objects.new(n,d);lighting.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();cameras[n]=o;return o
for n,conf in CFG['cameras'].items():camera(n,conf['position'],conf['target'],conf['lens_mm'])
s.camera=cameras['core_eye_front'];s.render.filepath=str(R/'renders/core_eye_front.png')
# Store actual world placements and declared safety boundaries; gameplay validation is separate.
layout={'units':'m','hall_interior':[40,36,20],'reactor_center':[0,0,0],'main_platform_surface_z':4.5,'upper_platform_surface_z':10,'gallery_width':3,'stairs':{'rise':4.5,'steps':25,'riser':.18,'run':7,'tread':.28,'width':2.4},'main_entry_clear_width':6.4,'camera_eye_height':1.65,'source_reuse':'Batch04 pump, pipe support and storage rack mesh appended, prior source unchanged','not_UE_tested':True,'not_exact_AZ3_replica':True}
(R/'layout.json').write_text(json.dumps(layout,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
if '--render' in sys.argv:
 names=sys.argv[sys.argv.index('--render')+1:] or ['core_eye_front']
 for n in names:
  if n not in cameras:continue
  roof.hide_render=n=='core_cutaway';s.camera=cameras[n];s.render.filepath=str(R/'renders'/f'{n}.png');bpy.ops.render.render(write_still=True)
 roof.hide_render=False
