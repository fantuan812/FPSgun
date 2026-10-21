import bpy,math
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(P/'NuclearPlant_FullSite.glb'))
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=12;s.cycles.use_denoising=False;s.render.resolution_x=960;s.render.resolution_y=640;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('Verification world');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.4,.45,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.65
for name,loc,power in [('Key',(25,-55,90),150000),('Fill',(-55,-8,70),80000)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=75;o=bpy.data.objects.new(name,d);s.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('GLB_Verification');d.type='ORTHO';d.ortho_scale=240;o=bpy.data.objects.new('GLB_Verification',d);s.collection.objects.link(o);o.location=(150,-175,145);o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler();s.camera=o
s.render.filepath=str(P/'GLB_imported_overview.png');bpy.ops.render.render(write_still=True)
