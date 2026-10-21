"""Read-only region GLB export. Source control.blend is never rewritten."""
import bpy,pathlib,json,hashlib
R=pathlib.Path(__file__).resolve().parent
src=R.parent/'Regions/control.blend';sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.duplicates_make_real(use_base_parent=False,use_hierarchy=False)
# Remove non-mesh instance anchors after realizing, and turn text into meshes.
for o in list(bpy.context.scene.objects):
 if o.type=='EMPTY':bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=next(iter(bpy.context.scene.objects));bpy.ops.object.convert(target='MESH')
n=len(bpy.context.scene.objects)
out=R.parent/'Regions/control.glb';bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_apply=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(out))
report={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'mesh_count_before':n,'mesh_count_reimport':sum(o.type=='MESH' for o in bpy.context.scene.objects),'libraries':len(bpy.data.libraries),'notes':'GLB preview/export, materials approximated; not UE tested.'}
report['pass']=report['source_unchanged'] and report['mesh_count_reimport']==n and not report['libraries'];(R/'region_export_check.json').write_text(json.dumps(report,indent=2))
assert report['pass'],report
