import bpy,pathlib,json
R=pathlib.Path(__file__).resolve().parent.parent;C=json.loads((R/'Config'/('design_v04.json' if (R/'Config/design_v04.json').exists() else 'design_v03.json' if (R/'Config/design_v03.json').exists() else ('design_v02.json' if (R/'Config/design_v02.json').exists() else 'design.json'))).read_text());out=[]
for mid in C['modules']:
 bpy.ops.wm.open_mainfile(filepath=str(R/'Assets'/f'{mid}.blend'));s=bpy.context.scene
 bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.gltf(filepath=str(R/'Exports'/f'{mid}.glb'),export_format='GLB',use_selection=False,export_apply=True,export_yup=True)
 out.append({'module':mid,'path':'Exports/'+mid+'.glb','bytes':(R/'Exports'/f'{mid}.glb').stat().st_size,'note':'Geometry and base PBR values; procedural Blender noise is not baked into GLB.'})
for name,variant in C.get('variants',{}).items():
 mid=variant['base_module'];vid=mid+'_narrow_045';bpy.ops.wm.open_mainfile(filepath=str(R/'Assets'/f'{mid}.blend'))
 for ob in bpy.context.scene.objects:
  if ob.type=='MESH':ob.scale=variant['scale'];ob['variant_reference']=variant['reference']
 bpy.ops.wm.save_as_mainfile(filepath=str(R/'Assets'/f'{vid}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(R/'Exports'/f'{vid}.glb'),export_format='GLB',use_selection=False,export_apply=True,export_yup=True)
 out.append({'module':vid,'base_family':mid,'blend':'Assets/'+vid+'.blend','path':'Exports/'+vid+'.glb','bytes':(R/'Exports'/f'{vid}.glb').stat().st_size,'note':'Exact X-scale .45 stock-family variant; same pre-model analytic reference as final scene.'})
(R/'Exports'/'manifest.json').write_text(json.dumps(out,indent=2))
