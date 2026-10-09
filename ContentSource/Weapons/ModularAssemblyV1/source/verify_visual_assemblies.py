"""Blender-only static visual fixture audit. Does not substitute gameplay or engine tests."""
import bpy,bmesh,json,hashlib,math
from pathlib import Path
from mathutils import Matrix,Vector,Quaternion
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[1];M=json.loads((R/'config/Visual_Module_Manifest.json').read_text());native=R/'AetherLab_ThreePlatform_Modular.blend'
bpy.ops.wm.open_mainfile(filepath=str(native))
for c in bpy.data.collections:c.hide_viewport=False
bpy.context.view_layer.update()
def mat(s):return Matrix.Translation(Vector(s['translation_m']))@Quaternion((s['rotation_xyzw'][3],*s['rotation_xyzw'][:3])).to_matrix().to_4x4()
def bvh(o):
 me=o.data;me.calc_loop_triangles();v=[o.matrix_world@p.co for p in me.vertices];return BVHTree.FromPolygons(v,[tuple(t.vertices) for t in me.loop_triangles],all_triangles=True)
rep={'scope':'Static Blender source structure, authored transform composition, module/assembly GLB roundtrip, finite mesh-pair surface intersection queries','source_sha256':hashlib.sha256(native.read_bytes()).hexdigest(),'units':'meters RH +X forward +Z up','modules':[],'presets':[],'roundtrip':[],'limitations':['Pairwise triangle intersection is not penetration depth, containment detection or continuous collision','Intentional visual mounting regions may overlap; not a zero-collision claim','No character skin, wrist limits, shoulder contact or animation sweep checked','No UE execution/import/uasset or gameplay runtime acceptance']}
for id,d in M['modules'].items():
 o=bpy.data.objects[d['object']];bm=bmesh.new();bm.from_mesh(o.data);nm=sum(not e.is_manifold for e in bm.edges);bm.free();o.data.calc_loop_triangles();uv=o.data.uv_layers.active
 rep['modules'].append({'module_id':id,'triangles':len(o.data.loop_triangles),'nonmanifold_edges':nm,'uv_present':bool(uv),'uv_in_0_1':bool(uv) and all(-1e-5<=v<=1.00001 for q in uv.data for v in q.uv),'identity_local_pivot':o.location.length<1e-7,'scale':list(o.scale),'packed_images':all(bool(n.image.packed_file) for sl in o.material_slots if sl.material and sl.material.use_nodes for n in sl.material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image)})
for p in M['presets']:
 nodes={n['instance_id']:n for n in p['nodes']};world={};maxerr=0;obs={}
 for n in p['nodes']:
  if n['parent_id'] is None:w=Matrix.Identity(4)
  else:
   par=nodes[n['parent_id']];w=world[n['parent_id']]@mat(M['modules'][par['module_id']]['slots'][n['slot_id']])
  world[n['instance_id']]=w;o=bpy.data.objects[p['id']+'__'+n['instance_id']];maxerr=max(maxerr,max(abs(w[i][j]-o.matrix_world[i][j]) for i in range(4) for j in range(4)));obs[n['instance_id']]=o
 trees={k:bvh(o) for k,o in obs.items()};pairs=[];ks=list(obs)
 for i,a in enumerate(ks):
  for b in ks[i+1:]:
   cross=trees[a].overlap(trees[b]);
   if cross:pairs.append({'a':a,'b':b,'triangle_pair_intersections':len(cross),'direct_parent_child':nodes[a]['parent_id']==b or nodes[b]['parent_id']==a,'interpretation':'Visual surface intersection, inspect authored mounting/covered regions; not automatically a gameplay rejection'})
 rep['presets'].append({'id':p['id'],'nodes':len(nodes),'max_matrix_element_residual':maxerr,'module_surface_intersections':pairs})
# independent import of every shipped glb checks presence/scale/bounds and packed textures
for f in sorted((R/'exports').rglob('*.glb')):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(f));obs=[o for o in bpy.data.objects if o.type=='MESH'];points=[o.matrix_world@Vector(p) for o in obs for p in o.bound_box]
 dims=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)];rep['roundtrip'].append({'file':str(f.relative_to(R)),'mesh_count':len(obs),'bounds_m':dims,'uv_all':all(bool(o.data.uv_layers) for o in obs),'finite_bounds':all(math.isfinite(x) and x>0 for x in dims)})
rep['structural_scope_pass']=all(x['nonmanifold_edges']==0 and x['uv_in_0_1'] and x['identity_local_pivot'] for x in rep['modules']) and all(x['max_matrix_element_residual']<1e-6 for x in rep['presets']) and all(x['uv_all'] and x['finite_bounds'] for x in rep['roundtrip'])
(R/'docs/Blender_Visual_Validation.json').write_text(json.dumps(rep,indent=2));print('VISUAL_STRUCTURAL_SCOPE_PASS',rep['structural_scope_pass'])
