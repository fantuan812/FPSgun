import bpy,json,pathlib
from mathutils import Vector
s=bpy.context.scene;d=bpy.context.evaluated_depsgraph_get();rows=[]
for side in [-1,1]:
 for y in [-.6,-.3,0,.3,.6]:
  for h in [.5,1.,1.5]:
   a=Vector((side*15,y,4.5+h));dire=Vector((-side,0,0));hit,p,n,f,o,m=s.ray_cast(d,a,dire,distance=9.)
   rows.append({'side':side,'y':y,'above_walkway':h,'segment_x':[side*15,side*6],'hit':hit,'object':o.name if hit else None,'point':list(p) if hit else None})
out={'scope':'30 horizontal bridge-axis rays at 0.5, 1.0 and 1.5m above deck, five lateral samples spanning 1.2m. Not full capsule sweep.','pass':not any(r['hit'] for r in rows),'rays':rows};pathlib.Path(__file__).with_name('bridge_horizontal_report.json').write_text(json.dumps(out,indent=2));print(json.dumps(out))
