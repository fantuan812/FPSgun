import bpy,pathlib
R=pathlib.Path(__file__).resolve().parents[1]
for n in ['pump_service_connected','site_with_pump_service']:
 p=R/'Region'/(n+'.blend');bpy.ops.wm.open_mainfile(filepath=str(p))
 for o in bpy.context.scene.objects:
  if o.name.startswith('CAPSULE_'):o.location.x=-15;o.location.y=-60
 for lib in bpy.data.libraries:lib.filepath='//../Geometry/'+pathlib.Path(lib.filepath).name
 bpy.ops.wm.save_as_mainfile(filepath=str(p),relative_remap=False)
