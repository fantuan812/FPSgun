import bpy,pathlib
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1]
def setup(path):
 bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=192;s.cycles.use_adaptive_sampling=True;s.cycles.adaptive_min_samples=64;s.cycles.adaptive_threshold=.03;s.cycles.use_denoising=False;s.cycles.max_bounces=4;s.render.resolution_x=1600;s.render.resolution_y=1280;s.render.resolution_percentage=100
 bpy.ops.object.camera_add();c=bpy.context.object;c.data.type='ORTHO';s.camera=c;return s,c
def render(s,c,n,loc,target,scale):
 c.location=loc;c.rotation_euler=(Vector(target)-c.location).to_track_quat('-Z','Y').to_euler();c.data.ortho_scale=scale;s.render.filepath=str(R/'Previews'/n);bpy.ops.render.render(write_still=True)
s,c=setup(R/'Region/pump_service_connected.blend');render(s,c,'pump_service_connected.png',(100,28,80),(2,-38,4),97)
s.render.resolution_x=1600;s.render.resolution_y=1800;render(s,c,'connected_top.png',(1,-38,100),(1,-38,0),91)
s.render.resolution_x=1600;s.render.resolution_y=1280;bpy.data.collections['SERVICE_ROOF_TOGGLE'].hide_render=True
for o in s.objects:
 if o.name.startswith('NorthWall_') and (o.name.endswith('_4') or o.name.endswith('_8')):o.hide_render=True
render(s,c,'service_cutaway.png',(43,-20,42),(-7,-61,4),50)
s,c=setup(R/'Region/site_with_pump_service.blend');render(s,c,'site_with_pump_service.png',(160,-215,185),(0,0,5),270)
print('OVERVIEW_RENDERS_COMPLETE',flush=True)
