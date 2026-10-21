import bpy,pathlib,json
R=pathlib.Path(__file__).resolve().parents[1];bpy.ops.wm.open_mainfile(filepath=str(R.parent/'Batch03/Region/pump_zone.blend'));mp={e['asset_id']:e for e in json.loads((R/'Geometry/asset_mesh_map.json').read_text())};data={}
# Make the comparison scene use the current package libraries, not the abandoned draft directory.
for path in sorted(set(e['library'] for e in mp.values())):
 es=[e for e in mp.values() if e['library']==path];full=(R/'Region'/path[2:]).resolve()
 with bpy.data.libraries.load(str(full),link=True) as (a,b):b.meshes=[e['mesh'] for e in es]
 for e,m in zip(es,b.meshes):data[e['asset_id']]=m
for o in bpy.context.scene.objects:
 if o.get('asset_id') in data:o.data=data[o['asset_id']]
bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
for lib in bpy.data.libraries:lib.filepath='//../Geometry/'+pathlib.Path(lib.filepath).name
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region/pump_annex_before_comparison_only.blend'),relative_remap=False)
