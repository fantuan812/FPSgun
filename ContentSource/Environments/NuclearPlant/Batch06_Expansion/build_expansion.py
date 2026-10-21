"""Layout-driven total assembly. Region producers own their own bounded collections."""
import bpy,json,math,pathlib,sys,hashlib
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent;C=json.loads((R/'layout.json').read_text());SPEC=json.loads((R/'connector_spec.json').read_text())['modules']
assert C['core']['scale']==1 and C['core']['center']==[0,0,0],'Core is a protected fixed-scale anchor'
REGION_BOUNDS={'control':[-24,24,38,62],'maintenance':[-68,-42,-16,18],'pumps':[42,68,-8,26],'loading':[18,66,-62,-42]}
for name,bounds in REGION_BOUNDS.items():
 if C['regions'][name]['bounds']!=bounds:raise ValueError('Region bounds are locked interface templates; edit region generator and references before moving '+name)
for name in SPEC:
 if not (R/'References'/'Connectors'/(name+'_technical.svg')).exists():raise ValueError('Missing pre-model technical reference '+name)
bpy.ops.wm.open_mainfile(filepath=str(R/C['core']['source']));s=bpy.context.scene
s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
# Relocate an inherited decorative text mesh clear of the real rear doorway in this copy only.
if 'Rear zone' in bpy.data.objects:bpy.data.objects['Rear zone'].location.x=-7
for o in list(bpy.data.objects):
 if o.type=='CAMERA':bpy.data.objects.remove(o,do_unlink=True)
def collection(n):
 c=bpy.data.collections.new(n);s.collection.children.link(c);return c
site=collection('B06_Site');roads=collection('B06_Roads');bridges=collection('B06_Elevated');context=collection('B06_Boundary');details=collection('B06_Wayfinding');cams=collection('B06_Cameras')
def mat(n,c,metal=0,rough=.7):
 if n in bpy.data.materials:return bpy.data.materials[n]
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
asphalt=mat('Court asphalt',(.075,.09,.1));steel=mat('Graphite structure',(.055,.075,.085),.75,.34);concrete=mat('Pale cast concrete',(.49,.52,.53));red=mat('Oxide red panels',(.2,.023,.018));yellow=mat('Safety ochre',(.88,.52,.055));white=mat('Offwhite wayfinding',(.81,.85,.84));earth=mat('B06 packed dark gravel',(.085,.105,.085));grass=mat('B06 muted boundary',(.07,.12,.065));silver=mat('Brushed pipe stainless',(.38,.44,.48),.85,.27)
cube=bpy.data.meshes.new('B06_unit_cube');cube.from_pydata([(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)],[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);cube.update();meshes={}
def box(n,p,d,m,c=site):
 if m.name not in meshes:me=cube.copy();me.materials.append(m);meshes[m.name]=me
 o=bpy.data.objects.new(n,meshes[m.name]);c.objects.link(o);o.location=p;o.scale=d;return o
def line(n,a,b,w,h,m,c,z=None):
 a,b=Vector(a),Vector(b);mid=(a+b)/2;o=box(n,mid,(w,h,(b-a).length),m,c);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def text(n,t,p,size=.8,rot=(math.pi/2,0,0),c=details):
 d=bpy.data.curves.new(n,'FONT');d.body=t;d.align_x='CENTER';d.size=size;d.extrude=.003;d.materials.append(white);o=bpy.data.objects.new(n,d);c.objects.link(o);o.location=p;o.rotation_euler=rot;return o
xmin,xmax,ymin,ymax=C['site_bounds'];box('Site datum',(0,0,-.30),(xmax-xmin,ymax-ymin,.5),earth)
def prefab(module_id,center,angle=0,c=site):
 palette={'#36434c':steel,'#b6babc':concrete,'#8b3430':red};rad=math.radians(angle)
 for i,part in enumerate(SPEC[module_id]['parts']):
  x,y,z,dx,dy,dz,color=part
  if color=='none':continue
  xx=center[0]+x*math.cos(rad)-y*math.sin(rad);yy=center[1]+x*math.sin(rad)+y*math.cos(rad)
  o=box(module_id+' / '+str(i),(xx,yy,center[2]+z),(dx,dy,dz),palette[color],c);o.rotation_euler.z=rad;o['module_id']=module_id
# Missing area files are explicit pending work, never silent completed placeholders.
loaded=[];pending=[]
for key,v in C['regions'].items():
 f=R/v['file']
 if not f.exists():pending.append(key);continue
 with bpy.data.libraries.load(str(f),link=False) as (src,dst):
  if v['collection'] not in src.collections:raise ValueError('Missing region collection '+v['collection'])
  dst.collections=[v['collection']]
 s.collection.children.link(dst.collections[0]);loaded.append(key)
if pending:raise FileNotFoundError('Formal assembly requires all region sources: '+','.join(pending))
# Complete inner service loop and add a non-overlapping external road network.
width=C['roads']['width'];roadsegs=[]
for label,path in [('outer',C['roads']['outer_loop']),('inner',C['roads']['inner_completion'])]+[('link',p) for p in C['roads']['links']]:
 for a,b in zip(path,path[1:]):
  dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy);mid=((a[0]+b[0])/2,(a[1]+b[1])/2,-.105)
  o=box('B06 road '+label,mid,(width,length+width if label=='outer' else length,.2),asphalt,roads);o.rotation_euler.z=-math.atan2(dx,dy);roadsegs.append([a,b])
  if length>14:
   for t in range(4,int(length)-3,7):
    p=(a[0]+dx*t/length,a[1]+dy*t/length,.008);o=box('Road center dash',p,(.10,2,.014),white,roads);o.rotation_euler.z=-math.atan2(dx,dy)
# Ground paths continue to real portals, not painted blind facades.
box('North pedestrian ribbon',(2,32,-.018),(4,12,.04),concrete,roads)
# External 3m walkway, 6m elevation, supports avoid road crossings.
p=C['elevated_connection']['path'];w=C['elevated_connection']['width']
if abs(w-5.4)>1e-6:raise ValueError('Paired bridge deck is approved5.4m assembly; update pre-model assembly reference before changing width')
for a,b in zip(p,p[1:]):
 a,b=Vector(a),Vector(b);direction=(b-a).normalized();normal=Vector((-direction.y,direction.x,0));mid=(a+b)/2
 # Explicit planar deck with corner landing.
 for j in range(math.ceil((b-a).length/6)):
  segment_length=min(6,(b-a).length-j*6);pos=a+direction*(j*6+segment_length/2)-Vector((0,0,.16))
  # Two 3m stock decks: overlap trimmed to disjoint3m+2.4m surfaces, no coplanar duplicate faces.
  for off,strip_width in [(-1.2,3),(1.5,2.4)]:
   o=box('B06 upper deck / paired trimmed stock',pos+normal*off,(strip_width,segment_length,.32),steel,bridges);o.rotation_euler.z=-math.atan2(direction.x,direction.y);o['module_id']='B06_BRIDGE';o['assembly']='two3m stock decks trim-union5.4m'
 ra=a+direction*(w/2) if list(a)==p[1] else a
 rb=b-direction*(w/2) if list(b)==p[1] else b
 for j in range(1,math.ceil((b-a).length/6)):
  pos=a+direction*(j*6)-Vector((0,0,.158));o=box('Bridge flush joint plate',pos,(w,.04,.32),steel,bridges);o.rotation_euler.z=-math.atan2(direction.x,direction.y)
 for side in [-1,1]:
  for z in [.15,.58,1.0725]:
   line('Elevated continuous rail',ra+normal*(w/2)*side+Vector((0,0,z)),rb+normal*(w/2)*side+Vector((0,0,z)),.055,.055,steel,bridges)
  for i in range(int((rb-ra).length/2.5)+1):
   q=ra+(rb-ra)*i/max(1,int((rb-ra).length/2.5))+normal*(w/2)*side
   box('Elevated rail post',q+Vector((0,0,.55)),(.06,.06,1.10),steel,bridges)
  # Red band only lower-middle, allowing distant scene visibility.
  line('Bridge oxide safety band',ra+normal*(w/2)*side+Vector((0,0,.4)),rb+normal*(w/2)*side+Vector((0,0,.4)),.035,.25,red,bridges)
box('Bridge corner landing / trimmed stock assembly',(-54,48,5.84),(w,w,.32),steel,bridges)
for zz in [6.15,6.58,7.0725]:
 line('Corner outer guard',(-54-w/2,48-w/2,zz),(-54-w/2,48+w/2,zz),.055,.055,steel,bridges)
 line('Corner outer guard',(-54-w/2,48+w/2,zz),(-54+w/2,48+w/2,zz),.055,.055,steel,bridges)
# Existing solid screen and equipment bank modules reused for standing-height bridge cover.
for a,b in zip(p,p[1:]):
 a,b=Vector(a),Vector(b);direction=(b-a).normalized();normal=Vector((-direction.y,direction.x,0))
 for dist in C['elevated_connection'].get('side_screen_centers',[]):
  if dist+2.5>(b-a).length:continue
  for side in [-1,1]:
   q=a+direction*dist+normal*(w/2)*side
   prefab('B06_SCREEN',q,0 if abs(direction.x)>.5 else 90,bridges)
for v in C['elevated_connection'].get('baffles',[]):prefab('B06_SERVICE_BANK',v['center'],v['angle'],bridges)
for x,y in [(-28,48),(-40,48),(-54,48),(-54,38),(-54,19)]:
 for side in [-1,1]:box('Bridge independent column',(x+side*1.3,y,2.84),(.26,.26,5.68),steel,bridges)
# Process connection to original service wing; crosses inner road with >6m under-pipe clearance.
for yy in [4]:
 cv=bpy.data.curves.new('B06 coolant bridge','CURVE');cv.dimensions='3D';cv.bevel_depth=.22;cv.bevel_resolution=3;sp=cv.splines.new('POLY');sp.points.add(1)
 for pt,co in zip(sp.points,[(30,yy,6.8),(42,yy,6.8)]):pt.co=(*co,1)
 cv.materials.append(silver);ob=bpy.data.objects.new('B06 coolant bridge',cv);bridges.objects.link(ob)
for x in [30,40]:
 for y in [2.7,5.3]:box('Coolant rack support',(x,y,3.2),(.18,.18,6.4),steel,bridges)
 box('Coolant rack crossbeam',(x,4,6.4),(.25,3,.2),steel,bridges)
# Post-reference connector construction is driven directly from the approved dimensional parts.
for idx,v in enumerate(C.get('infill',{}).get('service_shelters',[])):
 x,y,z=v['center'];ww,dd,hh=v['size'];assert v['size']==[14,8,4.5]
 box('Service compound hardstand',(x,y,-.025),(ww+2,dd+2,.05),concrete,site)
 prefab('B06_UTILITY_SHELTER',(x,y,z))
 for k in [-1,0,1]:prefab('B06_SERVICE_BANK',(x+k*3.5,y+1.5,z))
 text('Service compound ID','UTILITY / '+str(idx+1),(x,y-dd/2-.02,hh-.45),.55)
for v in C.get('infill',{}).get('service_banks',[]):prefab('B06_SERVICE_BANK',v['center'],v.get('angle',0))
for x,y,z,angle in C.get('infill',{}).get('screen_walls',[]):prefab('B06_SCREEN',(x,y,z),angle+90,details)
for v in C.get('walk_ribbons',[]):
 x,y,z=v['center'];ww,dd=v['size'];box('Protected pedestrian hardstand',(x,y,-.040),(ww,dd,.05),asphalt,roads)
# Boundary is contained and sparse. Do not scatter prop duplicates across every empty space.
for x in [-79,79]:
 box('Boundary retaining kerb',(x,0,.22),(.35,140,.44),concrete,context)
 for y in range(-64,69,8):box('Boundary pier',(x,y,1.2),(.3,.3,2.4),steel,context)
 for z in [.8,1.7,2.3]:box('Boundary rail',(x,0,z),(.06,140,.06),steel,context)
for y in [-69,69]:
 for xa,xb in ([(-79,-5),(5,79)] if y<0 else [(-79,79)]):
  box('Boundary end retaining kerb',((xa+xb)/2,y,.22),(xb-xa,.35,.44),concrete,context)
  for x in range(xa,xb,8):box('Boundary pier',(x,y,1.2),(.3,.3,2.4),steel,context)
# Gatehouse not a new playable building, just a compact guard canopy and visible access throat.
prefab('B06_GATE',(0,-68,0),0,details)
text('Site gate title','R / 01    INDUSTRIAL RESEARCH',(0,-68.18,5.27),.48)
for label,point in [('CONTROL  /  NORTH',(2,34,.035)),('SERVICE  /  WEST',(-34,-8,.035)),('COOLANT  /  EAST',(34,-8,.035))]:text('Road direction',label,point,.65,rot=(0,0,0))
# Explicit conservative character clearance reference, not an official Manny mesh.
proxy=collection('B06_Proxy_2p10m_not_Manny_mesh')
for x,y in [(0,-45),(34,-16),(-38,0),(2,33)]:
 box('2.10m clearance proxy torso',(x,y,1.14),(.52,.30,.78),yellow,proxy)
 for dx in [-.14,.14]:box('2.10m proxy leg',(x+dx,y,.40),(.18,.22,.8),yellow,proxy)
 box('2.10m proxy head',(x,y,1.92),(.30,.30,.36),yellow,proxy)
# One exterior sunlight, original interior lighting untouched.
ld=bpy.data.lights.new('B06 daylight','SUN');ld.energy=2;ld.angle=math.radians(20);lo=bpy.data.objects.new(ld.name,ld);cams.objects.link(lo);lo.rotation_euler=(math.radians(30),math.radians(-20),math.radians(-25))
for n,v in C['cameras'].items():
 d=bpy.data.cameras.new(n);o=bpy.data.objects.new(n,d);cams.objects.link(o);o.location=v['position'];o.rotation_euler=(Vector(v['target'])-o.location).to_track_quat('-Z','Y').to_euler();d.lens=v['lens'];d.clip_end=1000
s.camera=bpy.data.objects['site_overview'];s.render.filepath='//renders/site_overview.png';s.render.engine='BLENDER_EEVEE_NEXT';s.eevee.taa_render_samples=C['render']['samples'];s.eevee.shadow_pool_size='1024';s.render.resolution_x=C['render']['width'];s.render.resolution_y=C['render']['height'];s.render.resolution_percentage=100
import importlib.util
light_spec=importlib.util.spec_from_file_location('b06_lighting',R/'lighting.py');light_mod=importlib.util.module_from_spec(light_spec);light_spec.loader.exec_module(light_mod);light_mod.apply(s,C)
s['batch06_layout_sha256']=hashlib.sha256((R/'layout.json').read_bytes()).hexdigest();s['batch06_loaded_regions']=','.join(loaded);s['batch06_pending_regions']=','.join(pending)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'site_expansion.blend'),compress=True)
(R/'assembly_status.json').write_text(json.dumps({'loaded':loaded,'pending':pending,'object_count':len(s.objects),'source_preserved':True,'not_UE_validated':True},indent=2))
print('BATCH06_ASSEMBLED',loaded,'PENDING',pending)
