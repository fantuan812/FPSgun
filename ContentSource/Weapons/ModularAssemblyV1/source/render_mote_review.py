import bpy
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1];bpy.ops.wm.open_mainfile(filepath=str(R/'AetherLab_ThreePlatform_Modular.blend'));s=bpy.context.scene
for c in bpy.data.collections:c.hide_viewport=False
for o in bpy.data.objects:
 if o.type=='MESH' and o.name!='Studio_Floor':o.hide_render=True
s.camera.location=(.74,-1.3,.65);s.camera.rotation_euler=(Vector((.04,0,0))-s.camera.location).to_track_quat('-Z','Y').to_euler();s.camera.data.ortho_scale=.50;bpy.data.objects['Studio_Floor'].location.z=-.15
for variant in ['standard','compact_optic']:
 col=bpy.data.collections['ASSEMBLY_mote03.'+variant]
 for o in col.objects:o.hide_render=False
 s.render.filepath=str(R/'renders'/('mote03.'+variant+'.png'));bpy.ops.render.render(write_still=True)
 for o in col.objects:o.hide_render=True
