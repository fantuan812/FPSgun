"""Apply approved input lighting, proving geometry/materials unchanged from export baseline."""
import bpy,json,pathlib,sys,hashlib,array
R=pathlib.Path(__file__).resolve().parent;sys.path.insert(0,str(R));import lighting

def fingerprint():
 h=hashlib.sha256()
 for m in sorted(bpy.data.meshes,key=lambda x:x.name):
  h.update(m.name.encode())
  for data,field,n,typ in [(m.vertices,'co',3,'f'),(m.loops,'vertex_index',1,'i'),(m.polygons,'loop_start',1,'i'),(m.polygons,'loop_total',1,'i')]:
   buf=array.array(typ,[0])*(len(data)*n);data.foreach_get(field,buf);h.update(buf.tobytes())
  h.update(json.dumps([v.name if v else None for v in m.materials]).encode())
 for o in sorted(bpy.context.scene.objects,key=lambda x:x.name):
  if o.type=='LIGHT':continue
  h.update(json.dumps([o.name,o.type,o.data.name if o.data else None,[list(row) for row in o.matrix_world],o.instance_type,o.instance_collection.name if o.instance_collection else None],sort_keys=True).encode())
 for m in sorted(bpy.data.materials,key=lambda x:x.name):
  vals=[m.name,list(m.diffuse_color),m.use_nodes]
  if m.node_tree:
   for n in sorted(m.node_tree.nodes,key=lambda x:x.name):
    inputs=[]
    for sock in n.inputs:
     if not hasattr(sock,'default_value'):continue
     v=sock.default_value
     if hasattr(v,'__iter__') and not isinstance(v,str):v=list(v)
     if not isinstance(v,(str,int,float,bool,list,type(None))):v=str(v)
     inputs.append([sock.name,v])
    vals.append([n.name,n.bl_idname,inputs])
   vals.append(sorted([[l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name] for l in m.node_tree.links]))
  h.update(json.dumps(vals,sort_keys=True).encode())
 return h.hexdigest()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
source=R/'site_expansion.blend';before_sha=sha(source);bpy.ops.wm.open_mainfile(filepath=str(source));before=fingerprint();C=json.loads((R/'layout.json').read_text());lighting.apply(bpy.context.scene,C);bpy.context.view_layer.update();after=fingerprint();assert before==after,'Geometry or material changed'
bpy.context.scene['batch06_layout_sha256']=sha(R/'layout.json');bpy.ops.wm.save_as_mainfile(filepath=str(source),compress=True)
audit={'pass':True,'revision':'lighting/world/exposure only; no geometry/material/camera changes','geometry_and_materials_identical':True,'geometry_material_transform_fingerprint_before':before,'geometry_material_transform_fingerprint_after':after,'exported_baseline_source_sha256':before_sha,'current_source_sha256':sha(source),'lighting_input':C['lighting']}
(R/'Exports/lighting_only_source_audit.json').write_text(json.dumps(audit,indent=2));print('LIGHTING_ONLY_PASS',audit['current_source_sha256'])
