"""Update the local shared bay-wall mesh after removing coincident jamb contact faces."""
import bpy,json,pathlib
R=pathlib.Path(__file__).resolve().parents[1];aid='SM_NPP_ServiceBayWall_8m_A';e=next(e for e in json.loads((R/'Geometry/asset_mesh_map.json').read_text()) if e['asset_id']==aid);path=R/'Geometry'/pathlib.Path(e['library']).name
bpy.ops.wm.open_mainfile(filepath=str(path));old=bpy.data.meshes[e['mesh']];others={m for m in bpy.data.meshes if m!=old}
with bpy.data.libraries.load(str(R/'Assets'/aid/'model.blend'),link=False) as (a,b):b.objects=[aid]
o=b.objects[0];new=o.data;old.name='SUPERSEDED_BAY_MESH';new.name=e['mesh'];new.use_fake_user=True
bpy.data.libraries.write(str(path),others|{new},fake_user=True,compress=False)
print('UPDATED_SHARED_BAY_MESH',new.name,len(new.vertices),len(new.polygons),str(path))
