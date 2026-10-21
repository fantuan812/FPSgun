import bpy,pathlib,json,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent;bpy.ops.wm.open_mainfile(filepath=str(R.parent/'Regions/control.blend'));D=bpy.context.evaluated_depsgraph_get();s=bpy.context.scene
points={
'entry':[(2,38+i*.3,0) for i in range(23)],
'ground_bypass':[(10.5,43+i*.3,0) for i in range(58)],
'north_exit':[(2,59+i*.2,0) for i in range(15)],
'stairs':[(18+dx,41+(i+.5)*10.2/36,(i+1)*6/36) for i in range(36) for dx in [-.6,0,.6]],
'west_port': [(-24+i*.2,48,6) for i in range(51)],
'west_gallery':[(-14,48+i*.2,6) for i in range(56)],
'north_gallery':[(-14+i*.2,59,6) for i in range(161)],
'east_landing':[(18,51.2+i*.2,6) for i in range(40)]}
r={'file':bpy.data.filepath,'limits':'Static support/upward ray samples, not swept capsule or UE gameplay verification.','paths':{},'outside_bounds':[]}
for n,pp in points.items():
 bad=[]
 for p in pp:
  h,l,no,idx,o,ma=s.ray_cast(D,Vector(p)+Vector((0,0,.06)),Vector((0,0,1)),distance=2.1)
  if h:bad.append({'point':p,'object':o.name,'reason':'headroom','height':l.z-p[2]})
  h,l,no,idx,o,ma=s.ray_cast(D,Vector(p)+Vector((0,0,.06)),Vector((0,0,-1)),distance=.25)
  if not h:bad.append({'point':p,'reason':'support'})
 r['paths'][n]={'count':len(pp),'bad':bad}
for o in bpy.data.collections['B06_Control'].all_objects:
 if o.type in {'MESH','FONT','CURVE'}:
  corners=[o.matrix_world@Vector(v) for v in o.bound_box]
  if any(p.x< -24-.06 or p.x>24+.06 or p.y<38-.06 or p.y>62+.06 for p in corners):r['outside_bounds'].append(o.name)
(R/'office_static_checks.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
