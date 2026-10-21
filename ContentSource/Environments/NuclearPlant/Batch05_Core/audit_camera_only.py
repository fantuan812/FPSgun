"""Compare final camera-only source revision against the exact exported baseline.
Run once after renders complete: blender -b --python audit_camera_only.py
Does not save either source. Keeps original export_source_manifest untouched.
"""
import bpy,json,hashlib,struct,math
from pathlib import Path
R=Path(__file__).resolve().parent;O=R/'Exports'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def val(v):
    if isinstance(v,(str,bool,int,float)) or v is None:return v
    try:return [val(x) for x in v]
    except TypeError:return str(v)
def jhash(x):return hashlib.sha256(json.dumps(x,sort_keys=True,separators=(',',':'),allow_nan=False).encode()).hexdigest()
def matrix(m):return [float(x) for row in m for x in row]
def material(m):
    if m is None:return None
    a={'name':m.name,'diffuse_color':list(m.diffuse_color),'metallic':m.metallic,'roughness':m.roughness,'use_nodes':m.use_nodes}
    if m.use_nodes:
        a['nodes']=sorted([{'name':n.name,'type':n.bl_idname,'inputs':[(s.identifier,val(s.default_value)) for s in n.inputs if hasattr(s,'default_value')],'image':getattr(getattr(n,'image',None),'filepath',None),'operation':getattr(n,'operation',None),'blend_type':getattr(n,'blend_type',None),'color_ramp':[(e.position,list(e.color)) for e in n.color_ramp.elements] if hasattr(n,'color_ramp') else None} for n in m.node_tree.nodes],key=lambda x:x['name'])
        a['links']=sorted((l.from_node.name,l.from_socket.identifier,l.to_node.name,l.to_socket.identifier) for l in m.node_tree.links)
    return a

def fingerprint(path):
    bpy.ops.wm.open_mainfile(filepath=str(path));bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();cache={};records=[]
    for inst in deps.object_instances:
        ob=inst.object
        if ob.type not in {'MESH','CURVE','FONT','SURFACE'}:continue
        key=ob.original.as_pointer()
        if key not in cache:
            mesh=bpy.data.meshes.new_from_object(ob,preserve_all_data_layers=True,depsgraph=deps)
            h=hashlib.sha256()
            for v in mesh.vertices:h.update(struct.pack('<3f',*v.co))
            for p in mesh.polygons:
                h.update(struct.pack('<II?',len(p.vertices),p.material_index,p.use_smooth));h.update(struct.pack('<'+'I'*len(p.vertices),*p.vertices))
            for uv in mesh.uv_layers:
                h.update(uv.name.encode())
                for x in uv.data:h.update(struct.pack('<2f',*x.uv))
            cache[key]={'mesh_sha256':h.hexdigest(),'vertices':len(mesh.vertices),'polygons':len(mesh.polygons),'materials':[material(m) for m in mesh.materials]}
        records.append({'name':ob.name,'instance':bool(inst.is_instance),'matrix_world':matrix(inst.matrix_world),'mesh':cache[key],'hide_render':ob.hide_render})
    records.sort(key=lambda a:(a['name'],a['matrix_world']))
    cams={o.name:{'matrix_world':matrix(o.matrix_world),'lens':o.data.lens,'type':o.data.type,'ortho_scale':o.data.ortho_scale} for o in bpy.context.scene.objects if o.type=='CAMERA'}
    lights={o.name:{'matrix_world':matrix(o.matrix_world),'type':o.data.type,'energy':o.data.energy,'color':list(o.data.color)} for o in bpy.context.scene.objects if o.type=='LIGHT'}
    return {'file_sha256':sha(path),'exportable_geometry_materials_sha256':jhash(records),'evaluated_mesh_object_count':len(records),'cameras':cams,'lights_sha256':jhash(lights)}
manifest=json.loads((O/'export_source_manifest.json').read_text());baseline=R/'core_hall.blend1';current=R/'core_hall.blend'
assert sha(baseline)==manifest['source_sha256'],'Backup is not exact exported source baseline; do not guess.'
a=fingerprint(baseline);b=fingerprint(current)
r={'pass':a['exportable_geometry_materials_sha256']==b['exportable_geometry_materials_sha256'] and a['lights_sha256']==b['lights_sha256'],'exported_baseline_source_sha256':a['file_sha256'],'current_source_sha256':b['file_sha256'],'geometry_and_materials_identical':a['exportable_geometry_materials_sha256']==b['exportable_geometry_materials_sha256'],'lights_identical':a['lights_sha256']==b['lights_sha256'],'changed_cameras':[n for n in sorted(set(a['cameras'])|set(b['cameras'])) if a['cameras'].get(n)!=b['cameras'].get(n)],'baseline':a,'current':b,'scope':'Exact evaluated mesh topology, coordinates, UVs, polygon material indices, object world transforms, material nodes/inputs/links and light transforms/energy/color. Camera transforms are audited separately. No source or export files changed.'}
(O/'camera_only_source_audit.json').write_text(json.dumps(r,indent=2));print('CAMERA_ONLY_AUDIT',r['pass'],r['changed_cameras'])
if not r['pass']:raise SystemExit(1)
