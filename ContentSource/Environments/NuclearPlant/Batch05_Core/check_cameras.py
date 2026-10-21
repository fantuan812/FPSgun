"""Non-mutating support and immediate lens clearance audit. Run after rebuild."""
import bpy,json,pathlib
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
s=bpy.context.scene;dg=bpy.context.evaluated_depsgraph_get();out={}
for n in ['core_eye_front','core_eye_side','core_platform','core_entry']:
 o=bpy.data.objects[n]
 hit,loc,normal,index,obj,matrix=s.ray_cast(dg,o.location,Vector((0,0,-1)),distance=10)
 direction=o.rotation_euler.to_quaternion()@Vector((0,0,-1))
 obstruct=s.ray_cast(dg,o.location,direction,distance=.5)
 out[n]={'position':list(o.location),'support':obj.name if hit else None,'eye_above_support':o.location.z-loc.z if hit else None,'immediate_forward_0_5m_clear':not obstruct[0]}
 assert hit and 1.6<o.location.z-loc.z<1.7,n+' unsupported eye level'
 assert not obstruct[0],n+' immediate lens obstruction'
(R/'camera_standing_check.json').write_text(json.dumps(out,indent=2)+'\n')
print('CAMERA_SUPPORT_PASS',out)
