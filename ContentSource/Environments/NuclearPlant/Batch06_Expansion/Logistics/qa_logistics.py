import bpy,json,pathlib
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'logistics_combined.blend'));bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
# Envelope and centreline sampling at head/body heights; not UE character collision.
routes={'maintenance_east_entry':[(-41,0,0),(-45,0,0)],'maintenance_south_entry':[(-54,-17,0),(-54,-9,0)],'upper_bridge':[(-54,14,6),(-54,19,6)],'loading_gate':[(42,-41,0),(42,-54,0)],'stair_centre':[(-62.5,.48,0),(-62.5,10,6)]}
results={}
for name,(a,b) in routes.items():
 a,b=Vector(a),Vector(b);hits=[]
 for h in [1,2.05]:
  aa=a+Vector((0,0,h));bb=b+Vector((0,0,h));v=bb-aa
  hit,loc,nor,i,o,mat=bpy.context.scene.ray_cast(dg,aa,v.normalized(),distance=v.length)
  if hit:hits.append({'height':h,'object':o.name,'point':list(loc)})
 results[name]={'centreline_clear':not hits,'hits':hits}
report={'method':'body/head ray centreline only, radius0.5 design allowance not swept collision','routes':results,'region_collections':{n:len(bpy.data.collections[n].all_objects) for n in ['B06_Maintenance','B06_Loading']},'global_lights':[o.name for o in bpy.data.objects if o.type=='LIGHT'],'cameras':[o.name for o in bpy.data.objects if o.type=='CAMERA'],'dimensions':{'east_gate_width':6,'east_gate_height':6,'south_gate_width':3,'south_gate_height':3,'north_upper_port_width':3,'north_upper_port_height':3,'stairs_width':2.6,'stairs_riser':6/34,'stairs_tread':.28,'loading_gate_width':8,'ramp_width':2.6,'ramp_slope':1.1/11.5},'limitations':['not UE runtime navmesh/collision','Manny exact mesh not imported','cover intervals are layout goals not tactical simulation']}
(R/'qa_report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
