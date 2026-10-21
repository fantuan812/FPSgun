"""Original procedural pump yard. build(config) returns B06_Pumps, metres, no lights/world."""
import bpy,math,json,pathlib,sys
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parent
C=None
M={}
def mat(n,col,metal=0,rough=.5):
 m=bpy.data.materials.new('PUMP_'+n);m.diffuse_color=(*col,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*col,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
 noise=m.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=8
 bump=m.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.08;bump.inputs['Distance'].default_value=.025;m.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs[0],b.inputs['Normal']);return m
def add(o,n,m):
 o.name='B06_P_'+n
 for c in list(o.users_collection):c.objects.unlink(o)
 C.objects.link(o)
 if m:o.data.materials.append(m)
 return o
def box(n,p,d,m,bev=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);add(o,n,m)
 if bev:b=o.modifiers.new('Manufactured bevel','BEVEL');b.width=bev;b.segments=2
 return o
def cyl(n,p,r,h,m,axis='Z',v=32):
 bpy.ops.mesh.primitive_cylinder_add(vertices=v,radius=r,depth=h,location=p);o=add(bpy.context.object,n,m)
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
 return o
def beam(n,a,b,w,m):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(w,w,(b-a).length),m,.012);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def pipe(n,pts,r,ma=None):
 cv=bpy.data.curves.new(n,'CURVE');cv.dimensions='3D';cv.bevel_depth=r;cv.bevel_resolution=3;sp=cv.splines.new('POLY');sp.points.add(len(pts)-1)
 for p,co in zip(sp.points,pts):p.co=(*co,1)
 o=bpy.data.objects.new('B06_P_'+n,cv);C.objects.link(o);cv.materials.append(ma or M['silver']);return o
def label(n,t,p,size=.4):
 cv=bpy.data.curves.new(n,'FONT');cv.body=t;cv.align_x='CENTER';cv.size=size;cv.extrude=.001;o=bpy.data.objects.new('B06_P_'+n,cv);C.objects.link(o);o.location=p;o.rotation_euler=(math.pi/2,0,0);cv.materials.append(M['white']);return o
def rail(n,a,b,z):
 a,b=Vector((a[0],a[1],z)),Vector((b[0],b[1],z));L=(b-a).length
 for i in range(math.ceil(L/2)+1):
  p=a+(b-a)*i/math.ceil(L/2);beam(n+'post',p,p+Vector((0,0,1.1)),.055,M['steel'])
 for h in [.12,.6,1.1]:beam(n+'bar',a+Vector((0,0,h)),b+Vector((0,0,h)),.055,M['red'] if h==1.1 else M['silver'])
def build(config):
 global C,M
 old=bpy.data.collections.get('B06_Pumps')
 if old:
  for o in list(old.all_objects):bpy.data.objects.remove(o,do_unlink=True)
  bpy.data.collections.remove(old)
 C=bpy.data.collections.new('B06_Pumps');bpy.context.scene.collection.children.link(C)
 for n,c in config['palette'].items():M[n]=mat(n,c,.65 if n in ['steel','silver'] else .1)
 M['yellow']=mat('safety',(0.72,.46,.06));M['white']=mat('letter',(0.75,.8,.8));M['black']=mat('black',(.018,.022,.025));M['glass']=mat('glass',(.035,.12,.15),.4,.25)
 xmin,xmax,ymin,ymax=config['bounds'];dx,dy,dz=Vector(config['origin'])-Vector((42,-8,0))
 # Existing Batch04 geometry reused with local materials, no source modifications.
 with bpy.data.libraries.load(str(ROOT/'reuse.blend'),link=False) as(a,b):b.objects=['REUSED_B04_Pump_0_0','REUSED_B04_StorageRack_0_0']
 pump,rack=b.objects
 for mat0 in pump.data.materials:
  if mat0 and mat0.use_nodes:
   b=mat0.node_tree.nodes.get('Principled BSDF')
   if b and b.inputs['Base Color'].default_value[1]>.15:
    b.inputs['Base Color'].default_value=(.10,.12,.12,1);mat0.diffuse_color=(.10,.12,.12,1)
 box('yard slab',((xmin+xmax)/2,(ymin+ymax)/2,-.15),(xmax-xmin,ymax-ymin,.3),M['floor'])
 # Keep clear 4m continuous central maintenance artery.
 for x in range(43,68,2):
  for y in [5.95,10.05]:box('maintenance edge',(x,y,.012),(1,.08,.012),M['yellow'],0)
 for i,(x,y,z) in enumerate(config['pumps']):
  o=pump.copy();o.data=pump.data;C.objects.link(o);o.location=(x-2,y,z);o.rotation_euler=(0,0,0);o.name=f'B06_P_ReusePump_{i}'
  box('pump foundation',(x,y,.06),(4.5,2.5,.12),M['concrete']);label('pump number',f'P {i+1:02}',(x,y-1.27,.35),.32)
  # Branches deliberately routed away from main walkway; flange connections at pump body height.
  outer_y=-6 if y<8 else 17
  pipe('pump outlet',[(x-2,y,1.1),(x-2.6,y,1.1),(x-2.6,outer_y,1.1),(x-2.6,outer_y,3.2 if y>8 else 1.1),(max(48,x-2.6),outer_y,3.2 if y>8 else 1.1)],.16)
  cyl('pump flange',(x-2.05,y,1.1),.24,.1,M['steel'],'X')
  cyl('isolation valve',(x-2.6,(outer_y+y)/2,1.1),.25,.35,M['red'],'Y')
  cyl('valve handwheel',(x-2.6,(outer_y+y)/2,1.55),.28,.06,M['red'])
 for y in [-6,17]:
  hz=3.2 if y>8 else 1.1
  pipe('ground header',[(48,y,hz),(64,y,hz)],.22)
  for x in [48,54,60,64]:
   box('header shoe',(x,y,(hz-.22)/2),(.35,.65,hz-.22),M['steel'])
 # Two substantial upright buffer tanks.
 for i,(x,y,z) in enumerate(config['tanks']):
  box('tank pad',(x,y,.1),(4.8,4.8,.2),M['concrete']);cyl('tank body',(x,y,4.7),1.8,7.4,M['silver'],v=64)
  for zz in [1,2,6.7,8.4]:cyl('tank seam',(x,y,zz),1.84,.12,M['steel'],v=64)
  cyl('tank red band',(x,y,6.1),1.815,.7,M['red'],v=64);cyl('tank crown',(x,y,8.44),1.75,.12,M['steel'],v=64)
  for ox in [-1.175,1.175]:
   for oy in [-1.175,1.175]:box('tank leg',(x+ox,y+oy,.5),(.25,.25,1),M['steel'])
  label('tank tag',f'T {i+1:02}',(x,y-1.83,4.9),.65)
  outer_y=-6 if y<8 else 17
  pipe('tank lower tie',[(x,y,1.1),(x-2.4,y,1.1),(x-2.4,outer_y,1.1),(x,outer_y,1.1),(x,outer_y,3.2 if y>8 else 1.1)],.22)
 # Clear high-level pipeline from declared western interface to vessel sides.
 port=config['pipe_port'];py=port[1];z=port[2]
 pipe('interface main',[(42,py,z),(60,py,z),(60,-1,z),(62.2,-1,z)],config['pipe_radius'])
 pipe('upper transfer',[(60,py,z),(60,config['tanks'][1][1],z),(62.2,config['tanks'][1][1],z)],.22)
 for x,gy in config['gantries']:
  for y in [gy-1.2,gy+1.2]:box('pipe gantry',(x,y,3.05),(.22,.22,6.1),M['steel'])
  box('gantry head',(x,gy,6.25),(.3,3,.3),M['steel'])
  box('pipe saddle',(x,gy,6.49),(.3,.4,.18),M['steel'])
 # Maintenance hall, open south-facing service door 6m x 4m.
 a,b,c,d=config['hall_bounds'];mid=(a+b)/2
 box('hall floor',(mid,(c+d)/2,-.08),(b-a,d-c,.16),M['concrete'])
 box('hall north',(mid,d-.125,3.85),(b-a,.25,7.7),M['concrete'])
 for x in [a+.125,b-.125]:box('hall side',(x,(c+d)/2,3.85),(.25,d-c,7.7),M['concrete'])
 for l,r in [(a,53),(59,b)]:box('south door jamb',((l+r)/2,c+.125,3.85),(r-l,.25,7.7),M['concrete'])
 box('south door lintel',(56,c+.125,5.85),(6,.25,3.7),M['concrete'])
 box('hall roof',(mid,(c+d)/2,7.85),(b-a,d-c,.3),M['steel'])
 for x in [48,51,62,65]:box('service window',(x,c-.14,5.5),(1.5,.025,1.4),M['glass'])
 label('hall name','PUMP SERVICE',(56,c-.16,4.7),.45)
 for x in [49,63]:
  o=rack.copy();o.data=rack.data;C.objects.link(o);o.location=(x,23,0);o.rotation_euler=(0,0,0);o.name='B06_P_ReuseMaintenanceRack'
 # Rooftop maintenance platform not declared as gameplay traversable.
 # Functional fire/acoustic screens shelter technicians, not random freight clutter.
 for i,(x,y) in enumerate(config['fire_screens']):
  box('fire separation screen',(x,y,1.15),(3.6,.3,2.3),M['concrete'])
  box('screen red cap',(x,y,2.26),(3.6,.3,.08),M['red'])
  for xx in [x-1.3,x+1.3]:box('screen foot',(xx,y,.06),(.5,1.0,.12),M['steel'])
 # Translate all geometry if the configured region origin moves.
 for o in C.objects:o.location+=Vector((dx,dy,dz))
 C['purpose']='Grouped pump and buffer system with clear 4m maintenance artery';C['pipe_port']=port;C['template_bounds']=config['bounds']
 return C
if __name__=='__main__':
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.unit_settings.system='METRIC'
 cfg=json.loads((ROOT/'pump_config.json').read_text());build(cfg)
 out=ROOT.parent/'Regions/pumps.blend';bpy.ops.wm.save_as_mainfile(filepath=str(out),compress=True)
 report={'collection':'B06_Pumps','objects':len(C.objects),'units':'m','entry':[42,8,0],'clear_entry_width':4,'pipe_port':[42,4,6.8],'pipe_radius':.22,'local_sources':['reuse.blend'],'external_dependencies':[l.filepath for l in bpy.data.libraries],'UE_tested':False,'notes':['Central y6..10 aisle kept empty','Main pipeline above head height','Maintenance hall south door6m wide4m high']}
 (ROOT/'build_report.json').write_text(json.dumps(report,indent=2))
