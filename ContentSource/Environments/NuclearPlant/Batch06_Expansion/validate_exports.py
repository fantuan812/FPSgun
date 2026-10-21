import bpy, json, sys, os, importlib.util
from pathlib import Path
R=Path(__file__).resolve().parent;O=R/'Exports'
spec=importlib.util.spec_from_file_location('export_site',str(R/'export_site.py'));mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
kind=sys.argv[sys.argv.index('--')+1]
bpy.ops.wm.read_factory_settings(use_empty=True)
if kind=='glb':bpy.ops.import_scene.gltf(filepath=str(O/'NuclearPlant_FullSite.glb'))
elif kind=='fbx':bpy.ops.import_scene.fbx(filepath=str(O/'NuclearPlant_FullSite.fbx'))
bpy.context.view_layer.update()
s=mod.stats(bpy.context.scene.objects);src=json.load(open(O/'export_source_manifest.json'))
layout=json.loads((R/'layout.json').read_text())
s['regional_geometry_counts']={n:sum(1 for ob in bpy.context.scene.objects if ob.type=='MESH' and cfg['bounds'][0]<=ob.matrix_world.translation.x<=cfg['bounds'][1] and cfg['bounds'][2]<=ob.matrix_world.translation.y<=cfg['bounds'][3]) for n,cfg in layout['regions'].items()}
s['regional_geometry_matches']=s['regional_geometry_counts']==src['regional_geometry_counts']
s['clearance_proxy_objects']=sum('2.10m' in o.name for o in bpy.context.scene.objects)
s['format']=kind;s['mesh_object_count_matches']=s['mesh_objects']==src['mesh_objects'];s['triangle_count_matches']=s['triangles_including_instances']==src['triangles_including_instances']
s['max_bounds_error_m']=max(abs(s[k][i]-src[k][i]) for k in ['bounds_min_m','bounds_max_m'] for i in range(3))
s['material_name_count']=len(s['material_names']);s['material_count_matches']=len(s['material_names'])==len(src['material_names'])
s['cameras_and_lights']=[o.name for o in bpy.context.scene.objects if o.type in {'CAMERA','LIGHT'}]
s['missing_external_images']=[im.filepath for im in bpy.data.images if im.source=='FILE' and not im.packed_file and im.filepath and not os.path.exists(bpy.path.abspath(im.filepath))]
s['external_libraries']=[l.filepath for l in bpy.data.libraries]
s['prop_mesh_counts']={p:sum(o.type=='MESH' and o.name.startswith(p) for o in bpy.context.scene.objects) for p in ['RC_','EC_','VT_']}
s['scale_human_objects']=sum('Scale_1p80' in o.name for o in bpy.context.scene.objects)
s['pass']=s['regional_geometry_matches'] and s['mesh_object_count_matches'] and s['triangle_count_matches'] and s['max_bounds_error_m']<.001 and s['material_count_matches'] and not s['cameras_and_lights'] and not s['missing_external_images'] and not s['external_libraries'] and all(s['prop_mesh_counts'].values())
json.dump(s,open(O/f'readback_{kind}.json','w'),indent=2)
print('READBACK_RESULT',kind,s['pass'],s['mesh_objects'],s['triangles_including_instances'],s['max_bounds_error_m'])
