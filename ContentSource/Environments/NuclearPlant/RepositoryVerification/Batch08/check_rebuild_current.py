import bpy,json,sys,hashlib
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:];R=Path(args[0]);OUT=Path(args[1]);BASELINE=Path(args[2]) if len(args)>2 else None

def scene_report(root):
 bpy.ops.wm.open_mainfile(filepath=str(root/'Batch08_Refinement/site_refined.blend'))
 s=bpy.context.scene;bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();rows=[];cache={};verts=0;polys=0
 for inst in deps.object_instances:
  ob=inst.object
  if ob.type not in {'MESH','CURVE','FONT','SURFACE'}:continue
  key=ob.original.as_pointer()
  if key not in cache:
   me=bpy.data.meshes.new_from_object(ob,preserve_all_data_layers=False,depsgraph=deps)
   if not me or not me.vertices:continue
   data={'v':[[round(float(c),5) for c in v.co] for v in me.vertices],'f':[list(p.vertices) for p in me.polygons]}
   cache[key]=(hashlib.sha256(json.dumps(data,separators=(',',':')).encode()).hexdigest(),len(me.vertices),len(me.polygons))
   bpy.data.meshes.remove(me)
  digest,nv,np=cache[key];verts+=nv;polys+=np
  rows.append({'name':ob.name,'geometry':digest,'matrix':[[round(float(v),5) for v in row] for row in inst.matrix_world],'materials':[m.name if m else None for m in ob.data.materials]})
 rows.sort(key=lambda x:json.dumps(x,sort_keys=True))
 lights=[]
 for ob in s.objects:
  if ob.type!='LIGHT':continue
  d=ob.data;lights.append({'name':ob.name,'type':d.type,'energy':round(d.energy,5),'color':[round(v,5) for v in d.color],'matrix':[[round(v,5) for v in row] for row in ob.matrix_world],'angle':round(getattr(d,'angle',0),5),'size':round(getattr(d,'size',0),5),'size_y':round(getattr(d,'size_y',0),5)})
 world=[]
 if s.world and s.world.use_nodes:
  for n in s.world.node_tree.nodes:
   values={}
   for socket in n.inputs:
    if not hasattr(socket,'default_value'):continue
    v=socket.default_value
    if isinstance(v,(float,int)):v=round(v,5)
    else:
     try:v=[round(x,5) for x in v]
     except:v=str(v)
    values[socket.name]=v
   world.append({'name':n.name,'type':n.bl_idname,'inputs':values})
 lighting={'lights':sorted(lights,key=lambda x:x['name']),'world':sorted(world,key=lambda x:x['name']),'exposure':s.view_settings.exposure,'gamma':s.view_settings.gamma,'view_transform':s.view_settings.view_transform,'look':s.view_settings.look,'world_color':list(s.world.color) if s.world else None}
 lighting_hash=hashlib.sha256(json.dumps(lighting,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 q={'lighting_and_color_management_fingerprint':lighting_hash,'lighting_and_color_management':lighting,'objects':len(s.objects),'evaluated_geometry_instances':len(rows),'evaluated_vertices_including_instances':verts,'evaluated_polygons_including_instances':polys,'evaluated_geometry_fingerprint_round5':hashlib.sha256(json.dumps(rows,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'loaded_regions':s.get('batch06_loaded_regions'),'pending_regions':s.get('batch06_pending_regions'),'layout_sha256_in_scene':s.get('batch06_layout_sha256'),'layout_sha256_file':hashlib.sha256((root/'Batch08_Refinement/Config/design_v04.json').read_bytes()).hexdigest(),'libraries':[lib.filepath for lib in bpy.data.libraries],'source':'Batch08_Refinement/site_refined.blend','not_UE_runtime_test':True}
 materials=[]
 for mat in bpy.data.materials:
  nodes=[];links=[]
  if mat.use_nodes:
   for n in mat.node_tree.nodes:
    values={}
    for socket in n.inputs:
     if not hasattr(socket,'default_value'):continue
     v=socket.default_value
     if isinstance(v,(float,int)):v=round(v,5)
     elif isinstance(v,str):pass
     else:
      try:v=[round(x,5) for x in v]
      except:v=str(v)
     values[socket.identifier]=v
    nodes.append({'name':n.name,'type':n.bl_idname,'inputs':values,'operation':getattr(n,'operation',None),'blend_type':getattr(n,'blend_type',None),'noise_dimensions':getattr(n,'noise_dimensions',None)})
   links=sorted((l.from_node.name,l.from_socket.identifier,l.to_node.name,l.to_socket.identifier) for l in mat.node_tree.links)
  materials.append({'name':mat.name,'diffuse_color':[round(x,5) for x in mat.diffuse_color],'metallic':round(mat.metallic,5),'roughness':round(mat.roughness,5),'nodes':sorted(nodes,key=lambda x:x['name']),'links':links})
 q['material_nodes_fingerprint']=hashlib.sha256(json.dumps(sorted(materials,key=lambda x:x['name']),sort_keys=True,separators=(',',':')).encode()).hexdigest()
 cameras=[]
 for ob in s.objects:
  if ob.type=='CAMERA':cameras.append({'name':ob.name,'matrix':[[round(v,5) for v in row] for row in ob.matrix_world],'type':ob.data.type,'lens':round(ob.data.lens,5),'ortho_scale':round(ob.data.ortho_scale,5),'clip_start':round(ob.data.clip_start,5),'clip_end':round(ob.data.clip_end,5)})
 cr={'cameras':sorted(cameras,key=lambda x:x['name']),'engine':s.render.engine,'resolution_x':s.render.resolution_x,'resolution_y':s.render.resolution_y,'resolution_percentage':s.render.resolution_percentage}
 q['camera_and_render_fingerprint']=hashlib.sha256(json.dumps(cr,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 q['pass']=bool(q['objects']) and not q['libraries']
 return q
q=scene_report(R)
if BASELINE:
 original=scene_report(BASELINE)
 q['packaged_original']=original
 keys=['lighting_and_color_management_fingerprint','objects','evaluated_geometry_instances','evaluated_vertices_including_instances','evaluated_polygons_including_instances','evaluated_geometry_fingerprint_round5','loaded_regions','layout_sha256_file','material_nodes_fingerprint','camera_and_render_fingerprint']
 q['rebuild_matches_packaged_geometry']={k:q[k]==original[k] for k in keys}
 q['pass']=q['pass'] and original['pass'] and all(q['rebuild_matches_packaged_geometry'].values())
OUT.write_text(json.dumps(q,indent=2));print(json.dumps(q,indent=2));assert q['pass']
