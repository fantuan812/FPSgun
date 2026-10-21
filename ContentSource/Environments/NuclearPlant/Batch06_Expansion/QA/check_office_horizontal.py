import bpy,json,pathlib
from mathutils import Vector
S=bpy.context.scene;D=bpy.context.evaluated_depsgraph_get();R={'file':bpy.data.filepath,'limits':'Static line samples at body heights, not capsule sweep','rays':0,'hits':[]}
paths={'entry':[(2,37,0),(2,44,0)],'north_exit':[(2,59,0),(2,63,0)],'upper_west':[(-25,48,6),(-14,48,6),(-14,59,6),(18,59,6),(18,51.2,6)],'stairs':[(18,41+i*10.2/36,(i+.5)*6/36) for i in range(37)]}
for name,poly in paths.items():
 for a,b in zip(poly,poly[1:]):
  a,b=Vector(a),Vector(b);v=(b-a).normalized();n=Vector((-v.y,v.x,0)).normalized()
  for off in [-.5,0,.5]:
   for ht in [.5,1,1.65,2.05]:
    p=a+n*off+Vector((0,0,ht));h,l,no,f,o,m=S.ray_cast(D,p,v,distance=(b-a).length);R['rays']+=1
    if h:R['hits'].append({'path':name,'start':list(p),'hit':list(l),'object':o.name})
p=pathlib.Path(__file__).resolve().parent/'office_horizontal.json';p.write_text(json.dumps(R,indent=2));print(json.dumps(R))
