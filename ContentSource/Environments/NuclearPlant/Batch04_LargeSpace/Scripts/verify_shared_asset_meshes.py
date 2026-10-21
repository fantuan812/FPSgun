import bpy,json,pathlib,hashlib,struct
R=pathlib.Path(__file__).resolve().parents[1];manifest=json.loads((R/'manifest.json').read_text());mapping={e['asset_id']:e for e in json.loads((R/'Geometry/asset_mesh_map.json').read_text())};out=[]
def signature(me):
 h=hashlib.sha256()
 for v in me.vertices:h.update(struct.pack('<3f',*v.co))
 for p in me.polygons:h.update(struct.pack('<'+str(len(p.vertices))+'I',*p.vertices))
 return h.hexdigest()
for a in manifest['assets']:
 aid=a['asset_id'];e=mapping[aid];bpy.ops.wm.read_factory_settings(use_empty=True)
 with bpy.data.libraries.load(str(R/a['path']/'model.blend'),link=False) as (src,dst):dst.objects=[aid]
 model=dst.objects[0].data
 with bpy.data.libraries.load(str(R/'Geometry'/pathlib.Path(e['library']).name),link=True) as (src,dst):dst.meshes=[e['mesh']]
 packed=dst.meshes[0];h1=signature(model);h2=signature(packed);out.append({'asset_id':aid,'source_mesh_sha256':h1,'packed_mesh_sha256':h2,'status':'PASS' if h1==h2 else 'FAIL'})
(R/'Validation/shared_asset_mesh_consistency.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
