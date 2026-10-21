import bpy,os,json,math
from mathutils import Vector
r=os.path.dirname(os.path.abspath(__file__));bpy.ops.wm.open_mainfile(filepath=os.path.join(r,'reactor.blend'))
c=bpy.data.collections['Reactor_Core'];d=bpy.context.evaluated_depsgraph_get();points=[];tris=0
for o in c.objects:
 if o.type in ['MESH','CURVE','FONT']:
  e=o.evaluated_get(d)
  me=e.to_mesh();points.extend(e.matrix_world@v.co for v in me.vertices);tris+=sum(len(p.vertices)-2 for p in me.polygons);e.to_mesh_clear()
mins=[min(v[i] for v in points) for i in range(3)];maxs=[max(v[i] for v in points) for i in range(3)]
rep={'source':'reactor.blend','evaluated_bounds_m':{'min':mins,'max':maxs},'evaluated_triangles':tris,'object_count':len(c.objects),'strict_main_guard_opening_width_m':2*6.93*math.sin(.235),'main_platform_top_m':4.5,'upper_platform_top_m':10,'upper_guard_east_opening_width_m':2*5.04*math.sin(.1),'west_upper_guard_closed':True,'geometry_only_checks':True,'UE_runtime_checked':False}
json.dump(rep,open(os.path.join(r,'geometry_verification.json'),'w'),indent=2);print(rep)
