"""Non-destructive evaluated geometry export: run blender -b --python export_core.py.
Opens final source read-only in memory, realizes evaluated collection instances and
converts curves/text to meshes in a separate export scene. Never saves source.
"""
import bpy, os, json, hashlib, time
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parent;OUT=R/'Exports';OUT.mkdir(exist_ok=True)
source=R/'core_hall.blend'
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def stats(objects):
    meshes=[o for o in objects if o.type=='MESH'];points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
    return {'mesh_objects':len(meshes),'unique_meshes':len({o.data.as_pointer() for o in meshes}),'vertices_including_instances':sum(len(o.data.vertices) for o in meshes),'triangles_including_instances':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes),'material_names':sorted({m.name for o in meshes for m in o.data.materials if m}),'bounds_min_m':[min(p[i] for p in points) for i in range(3)],'bounds_max_m':[max(p[i] for p in points) for i in range(3)]}

def export():
    before=digest(source);bpy.ops.wm.open_mainfile(filepath=str(source))
    origin=bpy.context.scene
    # Source geometry roof must remain included. Camera/light objects are not exported.
    roof=bpy.data.collections.get('02_Roof_Toggle')
    if roof:roof.hide_render=False;roof.hide_viewport=False
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
    # Snapshot instances before creating output scene, so template source geometry is
    # only emitted where an evaluated scene instance places it.
    snapshots=[];cache={};converted_types={};instance_count=0
    for inst in deps.object_instances:
        ob=inst.object
        if ob.type not in {'MESH','CURVE','FONT','SURFACE'}:continue
        key=ob.original.as_pointer()
        if key not in cache:
            mesh=bpy.data.meshes.new_from_object(ob,preserve_all_data_layers=True,depsgraph=deps)
            if not mesh or not len(mesh.vertices):continue
            cache[key]=mesh
        snapshots.append((ob.name,cache[key],inst.matrix_world.copy(),bool(inst.is_instance)))
        converted_types[ob.type]=converted_types.get(ob.type,0)+1
        if inst.is_instance:instance_count+=1
    scene=bpy.data.scenes.new('EXPORT_CORE_REALIZED');scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
    bpy.context.window.scene=scene
    for i,(name,mesh,matrix,is_instance) in enumerate(snapshots):
        ob=bpy.data.objects.new(f'{name}__{i:04}',mesh);scene.collection.objects.link(ob);ob.matrix_world=matrix;ob.select_set(True)
    for old_scene in list(bpy.data.scenes):
        if old_scene!=scene:bpy.data.scenes.remove(old_scene)
    bpy.context.view_layer.update()
    data=stats(scene.objects)
    data.update({'source_sha256':before,'source_file':'core_hall.blend','roof_included':True,'human_scale_figures_included':True,'human_scale_collection':'07_Scale_1p8m','cameras_and_light_objects_exported':False,'evaluated_instance_mesh_objects':instance_count,'source_geometry_types':converted_types,'material_fidelity':'Principled material factors exported; procedural noise/bump/shader networks are not baked and may not transfer. Blender source is appearance reference.','coordinate_units':'metres, z up in source; GLB format stores y up via exporter; FBX uses -Z forward / Y up conversion','external_dependencies':[]})
    with open(OUT/'export_source_manifest.json','w') as f:json.dump(data,f,indent=2)
    bpy.ops.export_scene.gltf(filepath=str(OUT/'NuclearPlant_Core.glb'),export_format='GLB',use_selection=True,export_apply=False,export_yup=True,export_cameras=False,export_lights=False,export_materials='EXPORT',export_animations=False,export_extras=False)
    bpy.ops.export_scene.fbx(filepath=str(OUT/'NuclearPlant_Core.fbx'),use_selection=True,object_types={'MESH'},use_mesh_modifiers=False,add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y',apply_unit_scale=True,path_mode='AUTO',use_custom_props=False)
    after=digest(source);assert before==after,'SOURCE CHANGED'
    data['source_sha256_after']=after
    data['files']={p.name:{'bytes':p.stat().st_size,'sha256':digest(p)} for p in OUT.glob('NuclearPlant_Core.*')}
    with open(OUT/'export_source_manifest.json','w') as f:json.dump(data,f,indent=2)
    print('EXPORT_COMPLETE',json.dumps(data['files']))
if __name__=='__main__':export()
