import bpy,pathlib,json,hashlib,math,datetime,struct
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=pathlib.Path('/workspace/shared/NuclearPlant_Cumulative_Final/NuclearPlant/Batch07_Refinement');O=pathlib.Path('/workspace/shared/Batch07_Independent_QA/v04');C=json.loads((R/'Config/design_v04.json').read_text());F=json.loads((R/'QA/reference_freeze.json').read_text());BR=json.loads((R/'QA/build_record.json').read_text());Q=json.loads((R/'QA/static_geometry.json').read_text());F2=json.loads((R/'QA/reference_freeze_v02.json').read_text());F3=json.loads((R/'QA/reference_freeze_v03.json').read_text());F4=json.loads((R/'QA/reference_freeze_v04.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def sig(o):
 h=hashlib.sha256();h.update(o.type.encode());h.update(repr(tuple(tuple(float(x) for x in row) for row in o.matrix_world)).encode())
 if o.type=='MESH':
  h.update(b''.join(struct.pack('<3f',*v.co) for v in o.data.vertices));h.update(repr(tuple(tuple(p.vertices) for p in o.data.polygons)).encode())
 if o.type in {'CURVE','FONT'}:h.update(repr((o.data.body if o.type=='FONT' else '',o.data.extrude,o.data.bevel_depth)).encode())
 return h.hexdigest()
def dependencies():
 return {'libraries':[l.filepath for l in bpy.data.libraries], 'images':[{'name':i.name,'filepath':i.filepath,'packed':bool(i.packed_file),'source':i.source} for i in bpy.data.images], 'fonts':[{'name':i.name,'filepath':i.filepath,'packed':bool(i.packed_file)} for i in bpy.data.fonts if i.filepath!='<builtin>']}
def bbox(o):
 vs=[o.matrix_world@Vector(v) for v in o.bound_box];lo=[min(v[i] for v in vs) for i in range(3)];hi=[max(v[i] for v in vs) for i in range(3)];return {'lo':lo,'hi':hi,'dimensions':[hi[i]-lo[i] for i in range(3)]}
def bvh(exclude_open_racks=False):
 vs=[];fs=[];owners=[];dg=bpy.context.evaluated_depsgraph_get()
 for o in bpy.context.scene.objects:
  if (exclude_open_racks and o.name.startswith('B07_PIPE_RACK')) or o.type not in {'MESH','CURVE','FONT'} or 'proxy' in o.name.lower() or any('Proxy' in c.name for c in o.users_collection):continue
  ob=o.evaluated_get(dg);me=ob.to_mesh();me.calc_loop_triangles();base=len(vs);vs.extend(o.matrix_world@v.co for v in me.vertices);fs.extend(tuple(base+i for i in t.vertices) for t in me.loop_triangles);owners.extend([o.name]*len(me.loop_triangles));ob.to_mesh_clear()
 tree=BVHTree.FromPolygons(vs,fs,all_triangles=True)
 def ray(p,v,d=40):
  loc,n,idx,dist=tree.ray_cast(Vector(p),Vector(v).normalized(),d)
  return None if idx is None else {'point':list(loc),'object':owners[idx],'distance':dist}
 return ray
out={'audit_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'reference_inputs':len(F['inputs']),'hash_mismatches':[p for p,h in F['inputs'].items() if sha(R/p)!=h],'frozen_before_build_record':F['utc']<BR['started_utc'],'v04_hash_mismatches':[p for p,h in F4['inputs'].items() if sha(R/p)!=h],'v04_before_build':F4['utc']<BR['started_utc'],'v04_freeze_utc':F4['utc'],'v03_hash_mismatches':[p for p,h in F3['inputs'].items() if sha(R/p)!=h],'v03_before_build':F3['utc']<BR['started_utc'],'v03_freeze_utc':F3['utc'],'v02_hash_mismatches':[p for p,h in F2['inputs'].items() if sha(R/p)!=h],'v02_frozen_before_build':F2['utc']<BR['started_utc'],'v02_freeze_utc':F2['utc'],'build_start_utc':BR['started_utc'],'freeze_model_absent_claim':F['model_exists_at_freeze'],'baseline_current_sha256':sha((R/C['source']).resolve()),'baseline_hash_matches':sha((R/C['source']).resolve())==F['source_sha256'],'files':{},'rays':{}}
for p in sorted((R/'Assets').glob('*.blend'))+sorted((R/'Regions').glob('*.blend')):
 bpy.ops.wm.open_mainfile(filepath=str(p));sc=bpy.context.scene;out['files'][str(p.relative_to(R))]={'opened':True,'scenes':len(bpy.data.scenes),'active_scene_objects':len(sc.objects),'mesh_objects':[{'name':o.name,**bbox(o)} for o in sc.objects if o.type=='MESH'] if p.parent.name=='Assets' else len([o for o in sc.objects if o.type=='MESH']),'dependencies':dependencies()}
# test identical ground rays identified as changed by producer, with actual geometry and object evidence
L=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text())
paths={n:[(*p,6 if n=='upper_link' else 0) for p in poly] for n,poly in L['pedestrian_routes'].items()};paths['core_front']=[(0,-26,0),(0,-10,0)];paths['core_rear']=[(2,10,0),(2,26,0)]
witnesses=[]
for name,poly in paths.items():
 if name=='upper_link':continue
 for a,b in zip(poly,poly[1:]):
  a,b=Vector(a),Vector(b);n=max(1,int((b-a).length/3))
  for i in range(n):witnesses.append((name,list(a+(b-a)*i/n+Vector((0,0,1.65)))))
for x,y in C['replace_shelter_centers']:
 for dx in [-4,0,4]:witnesses.append(('yard_apron',[x+dx,y-4.85,1.65]))
wits=[]
for kind,elevation in [('ground',0),('rising_9degree',.16)]:
 for name,p in witnesses:
  for i in range(16):
   a=i*math.tau/16;wits.append({'kind':kind,'route':name,'origin':p,'direction_index':i,'vector':[math.cos(a),math.sin(a),elevation]})
dense_origins=[('corner',[51,-38,1.65],135),('loading_NE',[47,-40,1.65],45),('loading_N55',[55,-41.2,1.65],90),('loading_N59',[59,-41.2,1.65],90),('loading_NW62',[62,-38,1.65],135),('apron_pump',[60,-36.85,1.65],135),('apron_cargo',[-16,-60.85,1.65],135),('rack_excluded_62',[62,-26.3,1.65],112.5),('rack_excluded_59',[59,-26.3,1.65],90),('rack_excluded_55',[55,-26.3,1.65],67.5)]
for name,p,deg in dense_origins:
 for dx in [-.1,0,.1]:
  for dy in [-.1,0,.1]:
   for da in [i*.25 for i in range(-20,21)]:
    a=math.radians(deg+da);wits.append({'kind':'ground_dense_local','route':name,'origin':[p[0]+dx,p[1]+dy,p[2]],'angle_deg':deg+da,'vector':[math.cos(a),math.sin(a),0]})
out['route_intrusion']={} 
for kind,path in [('before',(R/C['source']).resolve()),('after',R/'site_refined.blend')]:
 bpy.ops.wm.open_mainfile(filepath=str(path));sc=bpy.context.scene
 if kind=='before':base={o.name:sig(o) for o in sc.objects if o.type not in {'CAMERA','LIGHT'}}
 else:
  current={o.name:sig(o) for o in sc.objects if o.type not in {'CAMERA','LIGHT'}};out['actual_baseline_object_counts']={'before':len(base),'after':len(current),'preserved':sum(n in current and current[n]==h for n,h in base.items())};out['actual_removed']=sorted(set(base)-set(current));out['actual_changed']=[n for n in base.keys()&current.keys() if base[n]!=current[n]];out['undeclared_removed']=sorted((set(base)-set(current))-set(BR['intentional_removed_objects']));out['declared_removed_not_removed']=sorted(set(BR['intentional_removed_objects'])-(set(base)-set(current)));out['current_module_placements']=[{'name':o.name,'module_id':o.get('module_id'),'location':list(o.location),'rotation_z_deg':math.degrees(o.rotation_euler.z),**bbox(o)} for o in sc.objects if str(o.get('module_id','')).startswith('B07')];out['files']['site_refined.blend']={'opened':True,'active_scene_objects':len(sc.objects),'dependencies':dependencies()}
 if kind=='after':
  mismatches=[]
  for rn,r in C['regions'].items():
   for i,p in enumerate(r['placements']):
    name=f'{p["module"]} / {rn} / {i:02d}';o=bpy.data.objects.get(name)
    if o is None:mismatches.append({'name':name,'reason':'missing'});continue
    if max(abs(o.location[i]-p['position'][i]) for i in range(3))>1e-4 or abs(math.degrees(o.rotation_euler.z)-p['rz'])>1e-4 or max(abs(o.scale[i]-p.get('scale',[1,1,1])[i]) for i in range(3))>1e-4:mismatches.append({'name':name,'reason':'transform mismatch'})
  out['placement_spec_mismatches']=mismatches
 ray=bvh()
 if kind=='after':
  out['camera_support']={}
  for name in ['core_entry','pump_eye','logistics_eye']:
   o=bpy.data.objects[name];p=o.location;h=ray(p,[0,0,-1],3);f=ray(p,o.rotation_euler.to_quaternion()@Vector((0,0,-1)),.5)
   out['camera_support'][name]={'position':list(p),'support':h,'first_half_m_block':f,'eye_above_support_m':p.z-h['point'][2] if h else None}
 for w in wits:w[kind]=ray(w['origin'],w['vector'])
 out['route_intrusion'][kind]={}
 for name,poly in paths.items():
  hits=[];samples=0
  for a,b in zip(poly,poly[1:]):
   a,b=Vector(a),Vector(b);d=b-a;n=max(1,math.ceil(d.length/.25));unit=d.normalized();side=Vector((-unit.y,unit.x,0))
   for i in range(n+1):
    for off in [-1,-.5,0,.5,1]:
     p=a+d*i/n+side*off+Vector((0,0,.06));h=ray(p,[0,0,1],2.04);samples+=1
     if h:hits.append({'at':list(p),'object':h['object'],'hit':h['point']})
  out['route_intrusion'][kind][name]={'samples':samples,'hits':hits}
 if kind=='after':
  rackless=bvh(True)
  for w in wits:w['after_excluding_open_rack']=rackless(w['origin'],w['vector'])
 # retained back/side cover top heights at each replaced pad: horizontal eye ray from south apron toward north
 out['rays'][kind+'_pad_direct']=[{'center':[x,y],'origin':[x+dx,y-4.85,1.65],'hit':ray([x+dx,y-4.85,1.65],[0,1,0])} for x,y in C['replace_shelter_centers'] for dx in [-5,-4,-3,-2,0,2,3,4,5]]
 print('AUDIT_PHASE',kind,flush=True)
out['ray_summary']={}
for k in ['ground','rising_9degree','ground_dense_local']:
 out['ray_summary'][k]={}
 for target in ['after','after_excluding_open_rack']:
  ss=[w for w in wits if w['kind']==k];loss=[w for w in ss if w['before'] and w['before']['distance']<12 and (not w[target] or w[target]['distance']>=12)];gain=[w for w in ss if (not w['before'] or w['before']['distance']>=12) and w[target] and w[target]['distance']<12]
  out['ray_summary'][k][target]={'rays':len(ss),'before_near_occluded':sum(bool(w['before'] and w['before']['distance']<12) for w in ss),'after_near_occluded':sum(bool(w[target] and w[target]['distance']<12) for w in ss),'loss_count':len(loss),'gain_count':len(gain),'loss_evidence':loss}
out['ray_evidence']=wits
out['scene_sha256']=sha(R/'site_refined.blend')
(O/'independent_audit.json').write_text(json.dumps(out,indent=2));print('INDEPENDENT_AUDIT_DONE',json.dumps({k:out[k] for k in ['hash_mismatches','baseline_hash_matches','actual_baseline_object_counts','actual_changed','undeclared_removed']}),flush=True)
