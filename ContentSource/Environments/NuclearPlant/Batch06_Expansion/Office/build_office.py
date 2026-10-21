"""Original control-office wing. build(config) creates only B06_Control geometry.
Inputs: bounds [xmin,xmax,ymin,ymax], entry, upper_port, hall_height (>=10).
No scene reset, cameras, world or roads inside build(). Units metres.
"""
import bpy,math,json,pathlib,sys
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parent
C=None; M={}; ORIGIN=Vector((0,0,0))
def mat(n,rgb,metal=0,rough=.5,emit=0):
 m=bpy.data.materials.get(n) or bpy.data.materials.new(n);m.diffuse_color=(*rgb,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*rgb,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
 if emit:b.inputs['Emission Color'].default_value=(*rgb,1);b.inputs['Emission Strength'].default_value=emit
 return m
def put(o,n,m):
 o.name='B06_CTL_'+n
 for c in list(o.users_collection):c.objects.unlink(o)
 C.objects.link(o)
 if m:o.data.materials.append(m)
 o['region']='control';return o
def box(n,p,d,m,bevel=.02):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=put(bpy.context.object,n,m);o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:b=o.modifiers.new('Edge highlight','BEVEL');b.width=bevel;b.segments=2
 return o
def beam(n,a,b,w,m):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(w,w,(b-a).length),m,.01);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def label(n,t,p,size=.5,rot=(math.pi/2,0,0),m=None):
 cv=bpy.data.curves.new(n,'FONT');cv.body=t;cv.size=size;cv.align_x='CENTER';cv.extrude=.001;o=bpy.data.objects.new(n,cv);C.objects.link(o);o.name='B06_CTL_'+n;o.location=p;o.rotation_euler=rot;cv.materials.append(m or M['white']);return o
def rail(n,a,b,z):
 a=Vector((a[0],a[1],z));b=Vector((b[0],b[1],z));L=(b-a).length
 for h in [.55,1.1]:beam(n+'_bar',a+Vector((0,0,h)),b+Vector((0,0,h)),.055,M['yellow'])
 for i in range(math.ceil(L/1.8)+1):
  p=a+(b-a)*i/math.ceil(L/1.8);beam(n+'_post',p,p+Vector((0,0,1.1)),.065,M['steel'])
def build(config):
 if not (ROOT/'References/prebuild_projection_manifest.json').exists() or not (ROOT/'References/ai_reference_manifest.json').exists():raise RuntimeError('Missing required prebuild references')
 global C,M
 b=config['bounds'];x0,x1,y0,y1=map(float,b);cx=(x0+x1)/2;cy=(y0+y1)/2;w=x1-x0;d=y1-y0;z=float(config['entry'][2]);H=float(config.get('hall_height',12));UZ=float(config['upper_port'][2]);ex=float(config['entry'][0]);py=float(config['upper_port'][1]);px=float(config['upper_port'][0]);
 if w<44 or d<24 or w%4 or d%4 or abs(H-12)>1e-6 or abs(UZ-z-6)>1e-6:raise ValueError('Control wing requires width>=44 depth>=24 and >=4m above upper deck')
 if abs(px-x0)>1e-5 or not y0+6<py<y1-6:raise ValueError('Upper port must be on west face with interior landing space')
 C=bpy.data.collections.new(config.get('collection','B06_Control'));bpy.context.scene.collection.children.link(C)
 M={'concrete':mat('Pale cast concrete',(.49,.52,.53),0,.65),'steel':mat('Graphite structure',(.055,.075,.085),.75,.34),'red':mat('Oxide red panels',(.36,.035,.024),.35,.43),'floor':mat('Sealed aggregate floor',(.13,.17,.19),0,.5),'white':mat('Offwhite wayfinding',(.81,.85,.84)),'yellow':mat('Safety ochre',(.88,.52,.055),.15),'glass':mat('Control blue glass',(.08,.17,.20),.65,.22),'screen':mat('Control screen',(.03,.27,.32),.2,.28,.5),'black':mat('Screen bezel',(.008,.012,.014)), 'silver':mat('Brushed pipe stainless',(.38,.44,.48),.85,.27)}
 # Reuse previously built modular floor/roof/wall geometry unchanged at nominal 4m size.
 with bpy.data.libraries.load(str(ROOT/'Reused/architecture.blend'),link=False) as (src,dst):dst.objects=list(src.objects)
 proto={o.name:o for o in dst.objects}
 def reuse(aid,loc,rot=0,collection=None):
  o=proto[aid].copy();o.data=proto[aid].data;(collection or C).objects.link(o);o.location=loc;o.rotation_euler=(0,0,rot);o.name='B06_CTL_REUSE_'+aid;o['source']='Batch04 original modular mesh';return o
 for i in range(int(w/4)):
  for j in range(int(d/4)):reuse('SM_NPP_Floor_4x4_A',(x0+4*i,y0+4*j,z))
 # Whole reusable 4m wall panels; non-grid portal closures are explicitly parameter basic parts.
 for yy in [y0+.15,y1-.15]:
  for zz in [0,4,8]:
   for i in range(int(w/4)):
    xx=x0+4*i
    if zz<8 and xx<ex+6 and xx+4>ex-6:continue
    reuse('SM_NPP_Wall_Window_4m_A' if zz>=4 else 'SM_NPP_Wall_Solid_4m_A',(xx,yy,z+zz))
  # Excluded grid bay is [-4,8] for default entry x2.
  for aa,bb in [(ex-6,ex-2.1),(ex+2.1,ex+6)]:box('Portal_boundary_closure',((aa+bb)/2,yy,z+4),(bb-aa,.30,8),M['concrete'])
  box('Portal_header',(ex,yy,z+6.2),(12,.30,3.6),M['concrete'])
 for xx in [x0+.15,x1-.15]:
  for zz in [0,4,8]:
   for j in range(int(d/4)):
    yy=y0+4*j
    if xx<x0+1 and zz>=4 and yy<py+1.8 and yy+4>py-1.8:continue
    reuse('SM_NPP_Wall_Window_4m_A' if zz>=4 else 'SM_NPP_Wall_Solid_4m_A',(xx,yy,z+zz),math.pi/2)
 # West portal non-grid boundary closures, aperture width3.6m, top10m.
 for aa,bb in [(y0+4*math.floor((py-1.8-y0)/4),py-1.8),(py+1.8,y0+4*math.ceil((py+1.8-y0)/4))]:box('West_port_side_closure',(x0+.15,(aa+bb)/2,z+8),(.30,bb-aa,8),M['concrete'])
 box('West_port_bottom_closure',(x0+.15,py,z+5),(.30,4,2),M['concrete']);box('West_port_top_closure',(x0+.15,py,z+11),(.30,4,2),M['concrete'])
 # Repeating vertical articulation and clearstory glazing overlays.
 for x in [x0+.5,x0+8,x0+16,x1-16,x1-8,x1-.5]:
  box('South_pier',(x,y0+.38,z+H/2),(.32,.44,H),M['steel'])
  box('North_pier',(x,y1-.40,z+H/2),(.32,.44,H),M['steel'])
 for x in [x0+4,x0+12,x1-12,x1-4]:
  box('Clerestory_south',(x,y0+.34,z+8),(6.5,.035,2.4),M['glass'])
  box('Clerestory_frame',(x,y0+.38,z+6.75),(6.7,.08,.12),M['steel'])
 for x in [x0+.8,x1-.8]:
  for y in [y0+1,cy,y1-1]:box('Perimeter_column',(x,y,z+H/2),(.36,.36,H),M['steel'])
 # Roof in named child collection so the whole region can be shown as cutaway.
 roof=bpy.data.collections.new('B06_Control_Roof');C.children.link(roof)
 for k in range(6):
  y=y0+2+k*(d-4)/5;o=box('Roof_beam',(cx,y,z+H-.5),(w-.8,.25,.5),M['steel']);C.objects.unlink(o);roof.objects.link(o)
 for i in range(int(w/4)):
  for j in range(int(d/4)):reuse('SM_NPP_Roof_4x4_A',(x0+4*i,y0+4*j,z+H),collection=roof)
 def deck_strip(name,start,length,axis='X'):
  # Full 4m modules plus explicitly measured end closure; never scale whole assemblies.
  count=int(length/4);rem=length-count*4
  for i in range(count+(rem>0.0001)):
   L=4 if i<count else rem;offset=i*4+L/2;pxx,pyy=start
   dims=(L,3.6,.3) if axis=='X' else (3.6,L,.3);loc=(pxx+offset,pyy,UZ-.15) if axis=='X' else (pxx,pyy+offset,UZ-.15)
   o=box(name,loc,dims,M['steel']);o['asset_id']='CTL_Deck' if L==4 else 'PARAM_DeckEndClosure';o['nominal_length']=L
 # 6 m level: west portal landing, west gallery, north gallery, east stair landing.
 gx=x0+10;east=x1-6;ny=y1-3
 deck_strip('West_port_deck',(x0,py),gx-x0)
 deck_strip('West_gallery',(gx,py-1.8),ny-py+3.6,'Y')
 deck_strip('North_gallery',(gx-1.8,ny),east-gx+3.6)
 stair_start=y0+3;run=10.2;end=stair_start+run
 deck_strip('East_landing',(east,end),ny+1.8-end,'Y')
 for xx,yy in [(gx,py),(gx,ny),(east,ny),(east,end)]:box('Gallery_support',(xx,yy,(z+UZ-.3)/2),(.32,.32,UZ-z-.3),M['steel'])
 rail('West_port_south',(x0+.08,py-1.65),(gx-1.8,py-1.65),UZ);rail('West_port_north',(x0+.08,py+1.65),(gx-1.8,py+1.65),UZ)
 rail('West_gallery_inner',(gx+1.65,py-1.8),(gx+1.65,ny-1.8),UZ);rail('West_gallery_outer',(gx-1.65,py+1.8),(gx-1.65,ny+1.65),UZ)
 rail('North_gallery_south',(gx+1.8,ny-1.65),(east-1.8,ny-1.65),UZ)
 rail('North_gallery_north',(gx-1.65,ny+1.65),(east+1.65,ny+1.65),UZ)
 rail('East_gallery_outer',(east+1.65,end),(east+1.65,ny+1.65),UZ);rail('East_gallery_inner',(east-1.65,end),(east-1.65,ny-1.8),UZ)
 # Three identical reusable stair units, each rise2m/run3.4m/width3m/12treads.
 steps=36;rise=(UZ-z)/steps;tread=run/steps
 for unit in range(3):
  uy=stair_start+unit*run/3;uz=z+unit*(UZ-z)/3
  for i in range(12):
   o=box('Stair_tread_'+str(unit)+'_'+str(i),(east,uy+(i+.5)*tread,uz+(i+1)*rise-.06),(3,tread+.005,.12),M['steel'],.01);o['asset_id']='CTL_StairUnit';o['module_instance']=unit
  for side in [-1,1]:
   xx=east+side*1.4
   for nm,aa,bb,ww,mm in [('Stair_stringer',(xx,uy,uz-.05),(xx,uy+run/3,uz+(UZ-z)/3-.05),.18,M['steel']),('Stair_handrail',(xx,uy,uz+1.1),(xx,uy+run/3,uz+(UZ-z)/3+1.1),.055,M['yellow'])]:
    o=beam(nm,aa,bb,ww,mm);o['asset_id']='CTL_StairUnit';o['module_instance']=unit
   for i in range(0,13,3):
    pp=(xx,uy+i*tread,uz+i*rise);o=beam('Stair_post',pp,(xx,pp[1],pp[2]+1.1),.055,M['steel']);o['asset_id']='CTL_StairUnit';o['module_instance']=unit
 # Reuse existing, pre-referenced Batch05 console and cabinet assets.
 with bpy.data.libraries.load(str(ROOT/'Reused/props.blend'),link=False) as (src,dst):dst.collections=['CP_ReactorConsole','CP_ElectricalCabinetBank']
 pcols={c.name:c for c in dst.collections}
 def prop(kind,n,loc):
  o=bpy.data.objects.new('B06_CTL_'+n,None);o.instance_type='COLLECTION';o.instance_collection=pcols[kind];o.location=loc;C.objects.link(o);o['source']='Batch05 existing module and reference';return o
 for x in [cx-7,cx+7]:
  for yy in [y0+8,y0+12]:
   for dx in [-1.35,1.35]:prop('CP_ReactorConsole','Console',(x+dx,yy,z))
 # Solid central island creates a short approach and a real left/right bypass.
 box('Center_control_island',(ex,y0+9,z+.60),(3.8,1.6,1.2),M['concrete']);box('Center_island_top',(ex,y0+9,z+1.23),(4.0,1.8,.06),M['steel']);box('Island_status_panel',(ex,y0+9.2,z+1.625),(2.6,.18,.65),M['red'])
 for dx in [-.9,.9]:
  o=box('Island_panel_mount',(ex+dx,y0+9.2,z+1.28),(.12,.14,.08),M['steel']);o['asset_id']='CTL_Island'
 # Five 2.6m repeated display panel modules follow the pre-build dimensions.
 for j in range(5):
  xx=cx-5.2+j*2.6;box('Display_panel_frame_'+str(j),(xx,y1-5.1,z+1.85),(2.6,.4,3.7),M['steel']);box('Display_panel_screen_'+str(j),(xx,y1-5.315,z+1.85),(2.3,.03,3.1),M['screen']);label('Display_tag_'+str(j),['POWER','COOLANT','GRID','ALERT','SYSTEM'][j],(xx,y1-5.34,z+3.1),.28)
 label('Office_identity','CONTROL / K-17',(ex,y0+.34,z+5.2),.7)
 for xx in [x0+3,x1-3]:
  for yy in [y1-7,y1-4]:prop('CP_ElectricalCabinetBank','Cabinet',(xx,yy,z))
 # Lower cable conduit follows perimeter and terminates at equipment zones.
 for xx in [x0+1,x1-1]:box('Cable_tray',(xx,cy,z+3.2),(.4,d-2,.2),M['steel'])
 # High red identification spine and lower wayfinding strips.
 for xx in [x0+.35,x1-.35]:box('Red_wall_band',(xx,cy,z+5.4),(.12,d-.8,.65),M['red'])
 for xx in [ex-2.4,ex+2.4]:box('Entry_marking',(xx,y0+3,z+.006),(.12,5,.012),M['yellow'],0)
 for o in C.objects:
  if o.name.startswith(('B06_CTL_Center_control_island','B06_CTL_Center_island_top','B06_CTL_Island_status_panel')):o['asset_id']='CTL_Island'
  if o.name.startswith(('B06_CTL_Display_panel_frame_0','B06_CTL_Display_panel_screen_0','B06_CTL_Display_tag_0')):o['asset_id']='CTL_DisplayPanel'
 # Construction and interface metadata; no implicit scene modification.
 C['bounds']=b;C['entry']=config['entry'];C['upper_port']=config['upper_port'];C['walk_surface']=z;C['upper_surface']=UZ;C['design']='wide control hall + equipment alcoves + 6m gallery; no enclosed tiny office grid'
 return C
if __name__=='__main__':
 R=pathlib.Path(__file__).resolve().parent;cfg=json.loads((R/'office_config.json').read_text());bpy.ops.wm.read_factory_settings(use_empty=True);c=build(cfg);s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
 out=R.parent/'Regions/control.blend';out.parent.mkdir(exist_ok=True);bpy.ops.wm.save_as_mainfile(filepath=str(out),compress=True)
 (R/'built_dimensions.json').write_text(json.dumps({'bounds':cfg['bounds'],'entry':cfg['entry'],'upper_port':cfg['upper_port'],'hall_height':cfg.get('hall_height',12),'stair':{'rise':cfg['upper_port'][2]-cfg['entry'][2],'steps':36,'run':10.2,'width':3},'object_count':len(c.all_objects),'status':'built; independent QA pending'},indent=2))
