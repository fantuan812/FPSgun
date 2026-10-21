"""Export reusable local-origin component collections from the rebuilt parametric region."""
import bpy,pathlib,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R.parent/'Regions/pumps.blend'))
C=bpy.data.collections['B06_Pumps'];objects=list(C.objects);D=R/'Modules';D.mkdir(exist_ok=True)
def names(starts,exclude=()):return [o for o in objects if any(o.name.startswith('B06_P_'+p) for p in starts) and not any(o.name.startswith('B06_P_'+p) for p in exclude)]
sets={
 'buffer_tank':([o for o in names(['tank ']) if o.location.y<5 and 'lower tie' not in o.name],(64,-1,0)),
 'maintenance_hall':(names(['hall ','south door','service window']),(46,19,0)),
 'fire_screen':([o for o in names(['fire separation','screen ']) if abs(o.location.y-10.6)<.01 and o.location.x<50],(47.5,10.6,0)),
 'pipe_gantry':([o for o in names(['pipe gantry','gantry head','pipe saddle']) if abs(o.location.x-43)<.01],(43,4,0)),
 'reused_pump':([o for o in objects if o.name=='B06_P_ReusePump_0'],(50,-3,0)),
 'reused_rack':([o for o in objects if o.name=='B06_P_ReuseMaintenanceRack'],(49,23,0))}
index={}
for name,(src,origin) in sets.items():
 col=bpy.data.collections.new('MODULE_'+name)
 for o in src:
  q=o.copy();q.data=o.data.copy();q.location-=Vector(origin);col.objects.link(q)
 # Canonical module ports on +X; yard installs the tank rotated 180 degrees.
 if name=='buffer_tank':
  for z in [1.1,6.8]:
   bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.22,depth=.6,location=(2.1,0,z),rotation=(0,1.57079632679,0));q=bpy.context.object
   for c in list(q.users_collection):c.objects.unlink(q)
   col.objects.link(q);q.name='TankCanonicalNozzle'
 if name=='pipe_gantry':
  bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.22,depth=6,location=(0,0,6.8),rotation=(0,1.57079632679,0));q=bpy.context.object
  for c in list(q.users_collection):c.objects.unlink(q)
  col.objects.link(q);q.name='GantryCanonical6mPipe'
 dest=D/(name+'.blend');bpy.data.libraries.write(str(dest),{col},fake_user=True,compress=True)
 index[name]={'file':'Modules/'+dest.name,'collection':col.name,'objects':len(col.objects),'source':'reused Batch04' if name.startswith('reused') else 'reference-following procedural rebuild'}
(R/'module_index.json').write_text(json.dumps(index,indent=2))
