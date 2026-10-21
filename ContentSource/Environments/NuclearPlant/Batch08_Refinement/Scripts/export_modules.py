import bpy,pathlib,json,hashlib,struct,datetime
R=pathlib.Path(__file__).resolve().parent.parent;manifest=json.loads((R/'ALL_MODULES.json').read_text());result=[]
for m in manifest:
 p=R/m['blend'];bpy.ops.wm.open_mainfile(filepath=str(p));s=bpy.context.scene
 for o in s.objects:o.hide_set(False);o.hide_viewport=False;o.hide_render=False
 target=R/m['glb'];bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',export_apply=True,export_materials='EXPORT',export_yup=True)
 data=target.read_bytes();magic,ver,length=struct.unpack('<4sII',data[:12]);assert magic==b'glTF' and ver==2 and length==len(data);jslen,jstype=struct.unpack('<II',data[12:20]);j=json.loads(data[20:20+jslen]);assert j.get('meshes');r={'module':m['module_id'],'file':m['glb'],'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'source_blend_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'gltf_meshes':len(j['meshes']),'gltf_materials':len(j.get('materials',[])),'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'procedural_shader_limit':'Base PBR values exported; Blender Noise/Wave nodes are not baked into textures.'};result.append(r)
(R/'Exports/manifest.json').write_text(json.dumps(result,indent=2));print('B08_MODULE_EXPORTS_OK',len(result))
