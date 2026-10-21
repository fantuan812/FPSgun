import bpy,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent;bpy.ops.wm.open_mainfile(filepath=str(R.parent/'Regions/control.blend'));s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=12;s.cycles.use_denoising=False;s.render.resolution_x=1200;s.render.resolution_y=800;s.render.resolution_percentage=100;s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('Office preview daylight');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.46,.55,.68,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.5
for name,pos,power,size in [('Key',(-15,40,23),6000,18),('Fill',(16,48,16),4500,12),('Interior',(0,52,10),3500,10)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);s.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,50,0))-o.location).to_track_quat('-Z','Y').to_euler()
for name,loc,target,lens in [('control_eye',(2,39.5,1.65),(0,54,3.5),22),('control_upper',(-22,48,7.65),(12,56,5),26),('control_cutaway',(-48,10,38),(0,50,3),43)]:
 bpy.data.collections['B06_Control_Roof'].hide_render=name=='control_cutaway'
 for o in bpy.data.collections['B06_Control'].objects:
  if (('Wall_' in o.name and (o.location.y<38.4 or o.location.x<-23.6)) or (o.location.y<38.5 and any(v in o.name for v in ['Portal_','South_pier','Clerestory','Office_identity'])) or 'West_port_' in o.name and 'closure' in o.name):o.hide_render=name=='control_cutaway'
 d=bpy.data.cameras.new(name);d.lens=lens;o=bpy.data.objects.new(name,d);s.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();s.camera=o;s.render.filepath=str(R/(name+'.png'));bpy.ops.render.render(write_still=True)
