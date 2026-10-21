"""Build reusable connector prefabs only after pre-model reference acceptance."""
import bpy,json,pathlib,datetime,hashlib
R=pathlib.Path(__file__).resolve().parent;S=json.loads((R/'connector_spec.json').read_text());out=R/'Assets'/'Connectors';out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);materials={}
for hexcol in ['#36434c','#b6babc','#8b3430']:
 m=bpy.data.materials.new('B06 '+hexcol);rgb=[int(hexcol[i:i+2],16)/255 for i in [1,3,5]];m.diffuse_color=(*rgb,1);m.use_nodes=True;bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*rgb,1);bs.inputs['Metallic'].default_value=.65 if hexcol=='#36434c' else .1;bs.inputs['Roughness'].default_value=.55;materials[hexcol]=m
records=[]
for name,v in S['modules'].items():
 c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c)
 for i,part in enumerate(v['parts']):
  x,y,z,dx,dy,dz,col=part
  if col=='none':continue
  bpy.ops.mesh.primitive_cube_add(size=1,location=(x,y,z));o=bpy.context.object;o.name=f'{name} / {i}';o.dimensions=(dx,dy,dz);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  for cc in list(o.users_collection):cc.objects.unlink(o)
  c.objects.link(o);o.data.materials.append(materials[col]);o['module_id']=name
 bpy.data.libraries.write(str(out/(name+'.blend')),{c},fake_user=True,compress=True)
 records.append({'id':name,'collection':name,'file':'Assets/Connectors/'+name+'.blend','dimensions_overall':v['dims'],'pre_model_technical':'References/Connectors/'+name+'_technical.svg','ai_reference':'References/Connectors/'+name+'_AI_v1.png'})
bpy.ops.wm.save_as_mainfile(filepath=str(out/'connector_modules.blend'),compress=True)
(R/'connector_asset_manifest.json').write_text(json.dumps({'built_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'spec_sha256':hashlib.sha256((R/'connector_spec.json').read_bytes()).hexdigest(),'references_predate_build':True,'modules':records},indent=2))
