"""Batch06 logistics modules, metres. build(config=None) -> two world-space collections.
Does not reset world or add global cameras/lights. Fixed structural template; origins/palette/props configurable.
"""
import bpy, math, json, pathlib
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parent
C=None; CACHE={}; OFFSET=Vector((0,0,0))
def material(n,c,metal=0,rough=.55):
 m=bpy.data.materials.get(n) or bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*c,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
 return m
def box(n,p,d,m,bev=0):
 key=(tuple(d),m.name)
 if key not in CACHE:
  x,y,z=[a/2 for a in d];me=bpy.data.meshes.new(n+' mesh');me.from_pydata([(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)],[],[(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]);me.materials.append(m);CACHE[key]=me
 o=bpy.data.objects.new(n,CACHE[key]);C.objects.link(o);o.location=Vector(p)+OFFSET
 if bev:b=o.modifiers.new('Small edge highlight','BEVEL');b.width=bev;b.segments=2
 return o
def beam(n,a,b,w,m):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(w,w,(b-a).length),m);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def cyl(n,p,r,h,m):
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=h,location=Vector(p)+OFFSET);o=bpy.context.object;o.name=n
 for c in list(o.users_collection):c.objects.unlink(o)
 C.objects.link(o);o.data.materials.append(m)
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
 return o
def text(n,t,p,size,m,rot=(math.pi/2,0,0)):
 d=bpy.data.curves.new(n,'FONT');d.body=t;d.size=size;d.align_x='CENTER';d.extrude=.003;o=bpy.data.objects.new(n,d);C.objects.link(o);o.location=Vector(p)+OFFSET;o.rotation_euler=rot;d.materials.append(m)
def rail(n,a,b,z,steel,red):
 a,b=Vector((a[0],a[1],z)),Vector((b[0],b[1],z));count=max(1,math.ceil((b-a).length/2))
 for i in range(count+1):p=a+(b-a)*i/count;beam(n+' post',p,p+Vector((0,0,1.1)),.055,steel)
 for h in [.12,.58,1.1]:beam(n+' rail',a+Vector((0,0,h)),b+Vector((0,0,h)),.055,red if h==1.1 else steel)
def pallet(n,x,y,z,wood,steel):
 for yy in [-.42,0,.42]:box(n+' runner',(x,y+yy,z+.07),(1.2,.12,.14),wood)
 for xx in [-.48,-.24,0,.24,.48]:box(n+' slat',(x+xx,y,z+.16),(.18,1,.08),wood)
 box(n+' freight',(x,y,z+.65),(1.05,.88,.9),steel,.025)
def rack(n,x,y,steel,red,wood):
 # Actual Batch04 source reuse, unchanged 4x1x3m rack; copies share mesh.
 name='REUSED_B04_StorageRack_0_0'
 src=bpy.data.objects.get(name)
 if src is None:
  with bpy.data.libraries.load(str(ROOT/'Reused/batch04_reuse.blend'),link=False) as (a,b):b.objects=[name]
  src=b.objects[0]
 o=src.copy();o.data=src.data;C.objects.link(o);o.name=n+' REUSED_B04';o.location=Vector((x,y,0))+OFFSET
 for xx in [-1.3,0,1.3]:pallet(n+' cargo',x+xx,y,.15,wood,steel)
def container(n,x,y,l,steel,red,white):
 box(n+' body',(x,y,1.3),(l,2.6,2.6),red,.05)
 for xx in [x-l/2+.12,x+l/2-.12]:
  for yy in [y-1.2,y+1.2]:box(n+' corner',(xx,yy,1.3),(.13,.13,2.6),steel)
 for i in range(int(l/.4)):
  xx=x-l/2+.2+i*.4
  for yy in [y-1.315,y+1.315]:box(n+' corrugation',(xx,yy,1.3),(.08,.045,2.4),steel)
 for yy in [-.64,.64]:box(n+' door panel',(x+l/2+.035,y+yy,1.3),(.04,1.24,2.4),red)
 for xx in [x-l/2-.06,x+l/2+.06]:
  for yy in [-.6,.6]:box(n+' locking rod',(xx,y+yy,1.3),(.06,.05,2.25),white)
def build(config=None):
 global C,OFFSET,CACHE
 if config is None:config=json.loads((ROOT/'logistics_config.json').read_text())
 if config.get('template')!='maintenance_26x34_loading_48x20_v1':raise ValueError('Unknown topology template; dimensions require revalidation')
 pal=config['palette'];wall=material('B06 concrete',pal['concrete']);steel=material('B06 graphite',pal['steel'],.65,.4);red=material('B06 oxide red',pal['red'],.3,.5);floor=material('B06 logistics floor',pal['floor'],.05,.65);yellow=material('B06 safety ochre',(.75,.48,.055));white=material('B06 signs',(.75,.79,.79));wood=material('B06 pallet wood',(.27,.2,.12));glass=material('B06 muted glazing',(.08,.18,.22),.45,.25)
 out={}
 C=bpy.data.collections.new('B06_Maintenance');bpy.context.scene.collection.children.link(C);out[C.name]=C;OFFSET=Vector(config['maintenance_offset'])
 box('M floor',(-55,1,-.12),(26,34,.24),floor)
 # East wall gate y[-3,3], south pedestrian gate x[-55.5,-52.5], north elevated door x[-55.5,-52.5].
 box('M west wall',(-67.85,1,5.5),(.3,34,11),wall)
 for ya,yb in [(-16,-3),(3,18)]:box('M east wall',(-42.15,(ya+yb)/2,5.5),(.3,yb-ya,11),wall)
 box('M east gate lintel',(-42.15,0,8.5),(.3,6,5),wall)
 for xa,xb in [(-68,-55.5),(-52.5,-42)]:box('M south wall',((xa+xb)/2,-15.85,5.5),(xb-xa,.3,11),wall)
 box('M south lintel',(-54,-15.85,7),(3,.3,8),wall)
 for xa,xb in [(-68,-55.5),(-52.5,-42)]:box('M north wall',((xa+xb)/2,17.85,5.5),(xb-xa,.3,11),wall)
 box('M north below high door',(-54,17.85,2.9),(3,.3,5.8),wall);box('M north lintel',(-54,17.85,10),(3,.3,2),wall)
 # Structural columns on perimeter only, clear central 16m bay.
 for xx in [-67.5,-42.5]:
  for yy in [-15, -7,7,17]:box('M column',(xx,yy,5.5),(.28,.32,11),steel)
 for yy in [-14,-6,2,10,17]:
  beam('M roof bottom chord',(-67.5,yy,9.8),(-42.5,yy,9.8),.16,steel)
  for i in range(5):
   x=-67.5+i*5;beam('M roof diagonal',(x,yy,9.8),(x+2.5,yy,10.8),.1,steel);beam('M roof diagonal',(x+2.5,yy,10.8),(x+5,yy,9.8),.1,steel)
 roof=bpy.data.collections.new('B06_Maintenance_Roof');C.children.link(roof);save=C;C=roof
 box('M roof panel',(-55,1,11.1),(26,34,.2),wall)
 for yy in [-10,0,10]:box('M roof skylight',(-55,yy,11.22),(12,1.8,.04),glass)
 C=save
 # Two 6x8x8m service station modules; 3m aisle between them.
 for cx in [-57.8,-48.8]:
  for xx in [cx-2.9,cx+2.9]:
   for yy in [-6.9,.9]:
    box('M station column',(xx,yy,4),(.2,.2,8),steel)
    box('M station foot',(xx,yy,.25),(.4,.4,.5),wall)
    box('M station red base',(xx,yy,1.5),(.23,.23,2),red)
   box('M station runway',(xx,-3,7.8),(.25,8,.4),steel)
  box('M station workbench',(cx,-6.4,1),(4.6,.8,.15),steel)
  box('M station toolboard',(cx,-6.85,1.8),(4.6,.1,1.3),red)
  for dx in [-1.8,-.9,0,.9,1.8]:box('M station cabinet',(cx+dx,-6.4,.5),(.8,.7,.9),steel)
  box('M station bridge',(cx,-3,7.5),(6,.5,.5),yellow)
  box('M station trolley',(cx,-3,7.0),(1,.8,.5),steel)
  beam('M station cable',(cx,-3,6.8),(cx,-3,4.6),.035,steel)
  cyl('M station hook',(cx,-3,4.5),.16,.25,yellow)
 # Rack group at back-left, maintenance benches along south wall, central bay kept open.
 for x,y in config['rack_centers']:rack('M storage rack',x,y,steel,red,wood)
 for xx in [-64,-60,-48]:
  box('M workbench',(xx,-13,1),(2.6,1.2,.12),steel)
  for dx in [-1.1,1.1]:box('M workbench leg',(xx+dx,-13,.48),(.1,1,.96),steel)
  box('M toolback',(xx,-13.55,1.75),(2.6,.1,1.3),red)
  for dx in [-.8,-.4,0,.4,.8]:box('M hanging tool',(xx+dx,-13.62,1.75),(.1,.06,.65),white)
 # Marked repair pads rather than random clutter.
 for xx in [-57.8,-48.8]:
  box('M service pad',(xx,-3,.015),(5,7,.03),steel)
  for dx in [-2.5,2.5]:box('M repair bay edge',(xx+dx,-3,.035),(.08,7,.01),yellow)
  for yy in [-6.5,.5]:box('M repair bay edge',(xx,yy,.035),(5,.08,.01),yellow)
 # North mezzanine; staircase at x-62.4 from y0 to9.52; arrival opening avoids overhead platform.
 box('M mezzanine',(-56.5,14,5.85),(15,8,.3),steel)
 box('M bridge threshold',(-54,17.85,5.85),(3,.7,.3),steel)
 box('M stair landing',(-62.5,11.5,5.85),(3,3,.3),steel)
 box('M landing connector',(-61.5,14,5.85),(1,6,.3),steel)
 steps=34;run=9.52;start=.48
 for i in range(steps):
  z=(i+1)*6/steps;box('M stair tread',(-62.5,start+(i+.5)*run/steps,z-.075),(2.6,run/steps,.15),steel)
  box('M stair nosing',(-62.5,start+(i+.02)*run/steps,z+.004),(2.6,.045,.015),yellow)
 for xx in [-63.86,-61.14]:
  beam('M stair handrail',(xx,start,1.1),(xx,start+run,7.1),.055,red)
  for i in range(0,steps+1,4):
   yy=start+i*run/steps;zz=i*6/steps;beam('M stair railpost',(xx,yy,zz),(xx,yy,zz+1.1),.055,steel)
 rail('M mezz front',(-60.8,10),(-49,10),6,steel,red)
 rail('M mezz east',(-49,10),(-49,18),6,steel,red)
 # rear door exactly reaches bridge at y18. Keep x[-55.5,-52.5] clear.
 rail('M mezz west',(-64,10),(-64,18),6,steel,red)
 rail('M mezz rear west',(-64,17.6),(-55.6,17.6),6,steel,red);rail('M mezz rear east',(-52.4,17.6),(-49,17.6),6,steel,red)
 for xx in [-60,-50]:box('M mezz support',(xx,14,2.9),(.2,.2,5.8),steel)
 # readable exterior facade markings and industrial bands, not logos.
 for ya,yb in [(-16,-3),(3,18)]:box('M east red band',(-41.98,(ya+yb)/2,1.5),(.04,yb-ya,3),red)
 text('M gate sign','M / 02',(-41.94,0,7.0),.9,white,(math.pi/2,0,math.pi/2))
 text('M floor safety','MAINTENANCE',(-55,5,.03),.75,white,(0,0,0))
 # loading yard, open north interface; no scene-wide road or world.
 C=bpy.data.collections.new('B06_Loading');bpy.context.scene.collection.children.link(C);out[C.name]=C;OFFSET=Vector(config['loading_offset'])
 box('L yard apron',(42,-52,-.12),(48,20,.24),floor)
 # raised dock at south, ramp on west leaves broad manoeuvre court.
 box('L dock',(44,-59, .55),(40,5,1.1),wall)
 box('L dock fascia',(44,-56.47,.55),(40,.05,1.1),steel)
 for xx in [28,40,52,62]:box('L dock bumper',(xx,-56.35,.55),(.25,.22,.8),black:=steel)
 # six broad steps within region.
 for i in range(6):box('L dock stair',(22.5,-54.58-(i+.5)*.32,(i+1)*1.1/6-.08),(2.6,.32,.16),steel)
 box('L ramp top landing',(21.25,-57.8,.55),(5.5,2.6,1.1),wall)
 rail('L landing west',(18.5,-59.1),(18.5,-56.5),1.1,steel,red)
 rail('L landing south',(18.5,-59.1),(24,-59.1),1.1,steel,red)
 for xx in [18.45,21.15]:
  beam('L ramp handrail',(xx,-45,1.1),(xx,-56.5,2.2),.055,red)
  for i in range(7):
   yy=-45-i*11.5/6;zz=i*1.1/6;beam('L ramp railpost',(xx,yy,zz),(xx,yy,zz+1.1),.055,steel)
 # slope ramp 11m x2.4 toward dock, at western edge.
 verts=[(18.5,-45,0),(21.1,-45,0),(21.1,-56.5,1.1),(18.5,-56.5,1.1),(18.5,-45,-.12),(21.1,-45,-.12),(21.1,-56.5,.98),(18.5,-56.5,.98)]
 me=bpy.data.meshes.new('L ramp mesh');me.from_pydata(verts,[],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7)]);me.materials.append(steel);o=bpy.data.objects.new('L dock ramp',me);C.objects.link(o);o.location=OFFSET
 OFFSET.z+=1.1
 for x,y,l in config['containers']:container('L container',x,y,l,steel,red,white)
 OFFSET.z-=1.1
 for x,y in config['freight_pallets']:pallet('L freight pallet',x,y,1.1,wood,steel)
 # dock canopy and purposeful striped bay positions.
 for xx in [23,29,35,41,47,53,59,65]:box('L canopy post',(xx,-61,3.5),(.16,.16,7),steel)
 box('L loading canopy',(44,-59,7.01),(42,5.5,.18),steel)
 box('L canopy red fascia',(44,-56.23,6.8),(42,.1,.5),red)
 for xx in [26,32,38,44,50,56,62]:
  beam('L canopy brace',(xx-3,-61,5.8),(xx,-61,6.9),.12,steel);beam('L canopy brace',(xx,-61,6.9),(xx+3,-61,5.8),.12,steel)
 for xx in [30,42,54]:
  for dx in [-3.2,3.2]:box('L parking line',(xx+dx,-49,.015),(.08,12,.025),yellow)
  text('L bay number','B%02d'%int((xx-18)/12),(xx,-46,.035),.65,white,(0,0,0))
 # Paired functional cover islands; continuous 8m centre lane stays open.
 rack('L west cargo rack',28,-48,steel,red,wood)
 box('L west protective wall',(28,-50, .65),(8,.24,1.3),wall)
 box('L east maintenance back wall',(58,-44,2.2),(10,.22,4.4),wall)
 box('L east maintenance side wall',(63,-47,2.2),(.22,6,4.4),wall)
 box('L east maintenance canopy',(58,-47,4.5),(10,6.2,.18),steel)
 for xx in [53,63]:box('L shed front column',(xx,-50,2.2),(.15,.15,4.4),steel)
 box('L shed workbench',(58,-44.8,1),(6,1,.15),steel)
 for xx in [55.5,58,60.5]:box('L shed equipment',(xx,-45.3,1.7),(1.4,.55,1.2),red,.025)
 for xx in [50,52]:box('L protective barrier',(xx,-49,.6),(1.6,.5,1.2),wall,.03)
 # north gate clear width 8m [38,46], physical short barriers only outside opening.
 for xa,xb in [(18,38),(46,66)]:
  for xx in range(int(xa)+1,int(xb),3):box('L north bollard',(xx,-42.5,.45),(.16,.16,.9),yellow)
 text('L dock label','DISPATCH / 04',(44,-56.39,.72),.55,white)
 OFFSET=Vector((0,0,0));return out

def export_modules(cols):
 global C,OFFSET
 specs=[('maintenance_shell','B06_Maintenance',lambda n:n.startswith(('M floor','M west wall','M east wall','M south wall','M north wall','M column','M roof','M east gate','M south lintel','M north lintel')),(-55,1,0)),('stair_landing','B06_Maintenance',lambda n:n.startswith('M stair'),(-62.5,.48,0)),('service_station','B06_Maintenance',lambda n:n.startswith(('M station','M service pad','M repair bay')),(-57.8,-3,0)),('loading_dock','B06_Loading',lambda n:n.startswith(('L dock','L canopy','L loading canopy','L ramp','L landing')),(44,-59,0)),('container','B06_Loading',lambda n:n.startswith('L container'),(32,-59,1.1))]
 index={}
 for name,col,test,origin in specs:
  c=bpy.data.collections.new('MODULE_'+name);src=[]
  for o in cols[col].all_objects:
   if not test(o.name):continue
   if name=='service_station' and o.location.x>-53.3:continue
   if name=='container' and o.location.x>40:continue
   q=o.copy();c.objects.link(q);q.location-=Vector(origin);src.append(o.name)
  path=ROOT/'Modules'/(name+'.blend');bpy.data.libraries.write(str(path),{c},fake_user=True,compress=True)
  index[name]={'file':'Modules/'+name+'.blend','collection':c.name,'source_objects':src,'world_origin':origin,'note':'canonical composite export, no global light/camera; shell and dock are region-sized composites, repeated bays retained within'}
  for o in list(c.objects):bpy.data.objects.remove(o,do_unlink=True)
  bpy.data.collections.remove(c)
 # Explicit repeatable bays, derived from the pre-model module drawings.
 for name in ['maintenance_bay','dock_bay']:
  C=bpy.data.collections.new('MODULE_'+name);OFFSET=Vector((0,0,0));steel=bpy.data.materials['B06 graphite'];wall=bpy.data.materials['B06 concrete'];red=bpy.data.materials['B06 oxide red']
  if name=='maintenance_bay':
   for xx in [-12.5,12.5]:
    for yy in [-3.84,3.84]:box('Portal column',(xx,yy,5.5),(.28,.32,11),steel)
    box('Side concrete',(xx*1.0272,0,5.5),(.3,8,11),wall);box('Side red band',(xx*1.0272,0,1.5),(.32,8,3),red)
   for yy in [-3.84,3.84]:
    beam('Truss chord',(-12.5,yy,9.8),(12.5,yy,9.8),.16,steel)
    for i in range(5):
     x=-12.5+i*5;beam('Truss diagonal',(x,yy,9.8),(x+2.5,yy,10.8),.1,steel);beam('Truss diagonal',(x+2.5,yy,10.8),(x+5,yy,9.8),.1,steel)
  else:
   box('Dock deck',(0,0,.55),(6,5.5,1.1),wall);box('Canopy roof',(0,0,7.01),(6,5.5,.18),steel)
   for xx in [-2.9,2.9]:box('Canopy column',(xx,-2.5,3.5),(.16,.16,7),steel)
   box('Red fascia',(0,2.7,6.8),(6,.1,.5),red)
  bpy.data.libraries.write(str(ROOT/'Modules'/(name+'.blend')),{C},fake_user=True,compress=True)
  index[name]={'file':'Modules/'+name+'.blend','collection':C.name,'reference':'References/'+name+'_technical.svg','world_origin':[0,0,0]}
  for o in list(C.objects):bpy.data.objects.remove(o,do_unlink=True)
  bpy.data.collections.remove(C)
 (ROOT/'module_index.json').write_text(json.dumps(index,indent=2))

if __name__=='__main__':
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.unit_settings.system='METRIC'
 cols=build();regions=ROOT.parent/'Regions';regions.mkdir(exist_ok=True)
 for name,file in [('B06_Maintenance','maintenance.blend'),('B06_Loading','loading.blend')]:
  bpy.data.libraries.write(str(regions/file),{cols[name]},fake_user=True,compress=True)
 export_modules(cols)
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'logistics_combined.blend'),compress=True)
 info={'collections':list(cols),'objects':{n:len(list(c.all_objects)) for n,c in cols.items()},'units':'m','main_gate_width':6,'pedestrian_gate':[3,3],'stair':{'width':2.6,'rise':6,'treads':34,'tread_depth':.28},'upper_interface':[-54,18,6],'loading_entry':[42,-42,0],'loading_entry_width':8,'not_UE_tested':True,'formal_reference_guided':True,'reference_manifest':'References/reference_manifest.json','rebuilt_utc':__import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat()}
 (ROOT/'logistics_manifest.json').write_text(json.dumps(info,indent=2));print(json.dumps(info))
