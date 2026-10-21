import bpy,pathlib,math,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'logistics_combined.blend'))
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=False
# EEVEE for actual noise-free drafting
s.render.engine='CYCLES' if '--cycles' in __import__('sys').argv else 'BLENDER_EEVEE_NEXT'
s.render.resolution_x=1200;s.render.resolution_y=850;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Review world');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.3,.4,.5,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.5
s.view_settings.view_transform='AgX'
for n,p,power,size in [('Sunsoft',(-50,-10,45),17000,40),('Fill',(0,-40,30),15000,35)]:
 d=bpy.data.lights.new(n,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(n,d);s.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector((-25,-10,0))-o.location).to_track_quat('-Z','Y').to_euler()
# actual model previews, no reference artwork
for name,p,t in [('maintenance',(-27,-35,30),(-55,1,3)),('loading',(75,-82,28),(42,-51,1))]:
 roof=bpy.data.collections.get('B06_Maintenance_Roof');roof.hide_render=True
 d=bpy.data.cameras.new(name);d.type='PERSP';d.lens=42;o=bpy.data.objects.new(name,d);s.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector(t)-o.location).to_track_quat('-Z','Y').to_euler();s.camera=o;s.render.filepath=str(R/(name+'_review.png'));bpy.ops.render.render(write_still=True)
