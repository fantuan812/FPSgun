import bpy,pathlib
R=pathlib.Path(__file__).resolve().parent;bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
for o in list(bpy.data.objects):
 if o.name.startswith('Entry curb'):o.location.y=-22;o.dimensions.y=8
 elif o.name.startswith('Gravel planting edge'):o.location.y=-22;o.dimensions.y=8
 elif o.name.startswith('Boundary scrub'):
  if o.location.y<-29:bpy.data.objects.remove(o,do_unlink=True)
  elif o.location.y<-25:o.location.y=-24.5
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
