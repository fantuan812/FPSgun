import bpy,pathlib,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent.parent;S=bpy.context.scene;D=bpy.context.evaluated_depsgraph_get();out={}
for n in ['site_entry','service_street','north_connection']:
 o=bpy.data.objects[n];p=o.matrix_world.translation;hit,loc,normal,index,obj,matrix=S.ray_cast(D,p,Vector((0,0,-1)),distance=3)
 f=S.ray_cast(D,p,o.matrix_world.to_quaternion()@Vector((0,0,-1)),distance=.5)
 out[n]={'position':list(p),'support':obj.name if hit else None,'relative_eye_height':p.z-loc.z if hit else None,'forward0p5m_clear':not f[0]}
 assert hit and 1.60<p.z-loc.z<1.70 and not f[0],n
(R/'QA'/'camera_final.json').write_text(json.dumps(out,indent=2));print('CAMERAS_PASS',out)
