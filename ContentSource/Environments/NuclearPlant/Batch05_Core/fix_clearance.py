import bpy,pathlib
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
for o in list(bpy.context.scene.objects):
 if o.name.startswith(('Gallery brace','Gallery pillar')) and abs(o.location.y+12)<.01:bpy.data.objects.remove(o,do_unlink=True)
 elif o.name.startswith('Under gallery linear') and abs(o.location.y+10)<.01:o.location.y=-4
 elif o.name.startswith('Gallery pool') and abs(o.location.y+10)<.01:o.location.y=-4
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
