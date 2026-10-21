import os,bpy,pathlib,json,hashlib,math,datetime,struct,gc,sys,itertools
from mathutils import Vector
from mathutils.bvhtree import BVHTree
import numpy as np
R=pathlib.Path('/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement');O=pathlib.Path(os.environ.get('B08_QA_OUTPUT','/workspace/shared/Batch08_Independent_QA'));O.mkdir(parents=True,exist_ok=True);D=json.loads((R/os.environ.get('B08_DESIGN','Config/design.json')).read_text());B7=json.loads((R.parent/'Batch07_Refinement/Config/design_v04.json').read_text());SRC=(R/D['source']).resolve();TARGET=R/'site_refined.blend';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
sys.path.insert(0,str(R/'Scripts'));from analytic_geometry import meshpart
F=json.loads((R/os.environ.get('B08_FREEZE','QA/reference_freeze.json')).read_text());BR=json.loads((R/'QA/build_record.json').read_text())
out={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scene_sha256':sha(TARGET),'baseline_sha256':sha(SRC),'baseline_expected_sha256':'3b2f4e727d359b595d818551be04be7ceabaa8fe1504de1164754ada4740b25b','freeze':{'utc':F['utc'],'build_start':BR['started_utc'],'before_build':F['utc']<BR['started_utc'],'input_mismatches':[k for k,v in F['inputs'].items() if sha(R/k)!=v]},'assets':{},'ray_summary':{},'route_intrusion':{}}
def sig(o):
 h=hashlib.sha256();h.update(o.type.encode());h.update(repr(tuple(tuple(float(x) for x in row) for row in o.matrix_world)).encode());h.update(str((o.hide_render,o.hide_viewport)).encode())
 if o.type=='MESH':
  h.update(b''.join(struct.pack('<3f',*v.co) for v in o.data.vertices));h.update(repr(tuple((tuple(p.vertices),p.material_index,p.use_smooth) for p in o.data.polygons)).encode());h.update(repr([m.name if m else None for m in o.data.materials]).encode())
 if o.type in {'CURVE','FONT'}:h.update(repr((o.data.body if o.type=='FONT' else '',o.data.extrude,o.data.bevel_depth)).encode())
 h.update(repr([(m.name,m.type,getattr(m,'width',None),getattr(m,'segments',None),m.show_render,m.show_viewport) for m in o.modifiers]).encode());return h.hexdigest()
def deps():return {'libraries':[x.filepath for x in bpy.data.libraries],'images':[{'path':x.filepath,'packed':bool(x.packed_file),'source':x.source} for x in bpy.data.images],'fonts':[x.filepath for x in bpy.data.fonts if x.filepath!='<builtin>']}
def bounds(o):
 v=[o.matrix_world@Vector(x) for x in o.bound_box];lo=[min(v[i] for v in v) for i in range(3)];hi=[max(v[i] for v in v) for i in range(3)];return [lo,hi]
def spatial(exclude_decor=False):
 vv=[];ff=[];owners=[];dg=bpy.context.evaluated_depsgraph_get()
 for o in bpy.context.scene.objects:
  if o.type not in {'MESH','CURVE','FONT'} or 'proxy' in o.name.lower() or any('Proxy' in c.name for c in o.users_collection):continue
  if exclude_decor and (o.name.startswith('B08') or o.name.startswith('B07_PIPE_RACK')):continue
  ob=o.evaluated_get(dg);me=ob.to_mesh();me.calc_loop_triangles();base=len(vv);vv.extend(o.matrix_world@v.co for v in me.vertices);ff.extend(tuple(base+i for i in t.vertices) for t in me.loop_triangles);owners.extend([o.name]*len(me.loop_triangles));ob.to_mesh_clear()
 tree=BVHTree.FromPolygons(vv,ff,all_triangles=True)
 def ray(p,v,d=40):
  loc,n,idx,dist=tree.ray_cast(Vector(p),Vector(v).normalized(),d);return None if idx is None else {'point':list(loc),'object':owners[idx],'distance':dist}
 return ray
L=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text());paths={n:[(*p,6 if n=='upper_link' else 0) for p in poly] for n,poly in L['pedestrian_routes'].items()};paths['core_front']=[(0,-26,0),(0,-10,0)];paths['core_rear']=[(2,10,0),(2,26,0)]
witnesses=[]
for name,poly in paths.items():
 if name=='upper_link':continue
 for a,b in zip(poly,poly[1:]):
  a,b=Vector(a),Vector(b);n=max(1,int((b-a).length/3))
  for i in range(n):witnesses.append((name,list(a+(b-a)*i/n+Vector((0,0,1.65)))))
for x,y in B7['replace_shelter_centers']:
 for dx in [-4,0,4]:witnesses.append(('yard_apron',[x+dx,y-4.85,1.65]))
wits=[]
for kind,elev in [('ground',0),('rising_9degree',.16)]:
 for name,p in witnesses:
  for i in range(16):
   a=i*math.tau/16;wits.append({'kind':kind,'route':name,'origin':p,'vector':[math.cos(a),math.sin(a),elev]})
dense=[('corner',[51,-38,1.65],135),('loading_NE',[47,-40,1.65],45),('loading_N55',[55,-41.2,1.65],90),('loading_N59',[59,-41.2,1.65],90),('loading_NW62',[62,-38,1.65],135),('apron_pump',[60,-36.85,1.65],135),('apron_cargo',[-16,-60.85,1.65],135),('rack_excluded_62',[62,-26.3,1.65],112.5),('rack_excluded_59',[59,-26.3,1.65],90),('rack_excluded_55',[55,-26.3,1.65],67.5)]
for name,p,deg in dense:
 for dx,dy,di in itertools.product([-.1,0,.1],[-.1,0,.1],range(-20,21)):
  a=math.radians(deg+di*.25);wits.append({'kind':'ground_dense_local','route':name,'origin':[p[0]+dx,p[1]+dy,p[2]],'vector':[math.cos(a),math.sin(a),0]})
for phase,p in [('before',SRC),('after',TARGET)]:
 bpy.ops.wm.open_mainfile(filepath=str(p));scene=bpy.context.scene;current={o.name:sig(o) for o in scene.objects if o.type not in {'CAMERA','LIGHT'}}
 if phase=='before':base=current
 else:
  out['baseline_objects']={'before':len(base),'after':len(current),'preserved':sum(n in current and current[n]==h for n,h in base.items()),'removed':sorted(base.keys()-current.keys()),'changed':[n for n in base.keys()&current.keys() if base[n]!=current[n]],'added':sorted(current.keys()-base.keys())};out['scene_dependencies']=deps();out['placement_mismatches']=[]
  for rn,r in D['regions'].items():
   for i,p in enumerate(r['placements']):
    name=f'{p["module"]} / {rn} / {i:02d}';ob=bpy.data.objects.get(name)
    if ob is None or max(abs(ob.location[j]-p['position'][j]) for j in range(3))>1e-4 or abs(math.degrees(ob.rotation_euler.z)-p['rz'])>1e-4 or max(abs(ob.scale[j]-p.get('scale',[1,1,1])[j]) for j in range(3))>1e-4:out['placement_mismatches'].append(name)
  out['new_object_bounds']={o.name:bounds(o) for o in scene.objects if o.name.startswith('B08') and o.type=='MESH'}
 ray=spatial(False)
 for w in wits:w[phase]=ray(w['origin'],w['vector'])
 out['route_intrusion'][phase]={}
 for name,poly in paths.items():
  hits=[];samples=0
  for a,b in zip(poly,poly[1:]):
   a,b=Vector(a),Vector(b);d=b-a;n=max(1,math.ceil(d.length/.25));u=d.normalized();side=Vector((-u.y,u.x,0))
   for i in range(n+1):
    for off in [-1,-.5,0,.5,1]:
     q=a+d*i/n+side*off+Vector((0,0,.06));h=ray(q,[0,0,1],2.04);samples+=1
     if h:hits.append({'at':list(q),**h})
  out['route_intrusion'][phase][name]={'samples':samples,'hits':hits}
 if phase=='after':
  out['camera_support']={}
  for name in D['cameras']:
   c=bpy.data.objects[name];q=c.location;h=ray(q,[0,0,-1],3);f=ray(q,c.rotation_euler.to_quaternion()@Vector((0,0,-1)),.5);out['camera_support'][name]={'position':list(q),'support':h,'first_half_m_block':f}
 del ray;gc.collect();ray=spatial(True)
 for w in wits:w[phase+'_solid_only']=ray(w['origin'],w['vector'])
 del ray;gc.collect();print('AUDIT_PHASE',phase,flush=True)
for k in ['ground','rising_9degree','ground_dense_local']:
 out['ray_summary'][k]={}
 for mode in ['all_geometry','existing_solid_only']:
  a,b=('before','after') if mode=='all_geometry' else ('before_solid_only','after_solid_only');ss=[w for w in wits if w['kind']==k];near=lambda w,t:bool(w[t] and w[t]['distance']<12);loss=[w for w in ss if near(w,a) and not near(w,b)];gain=[w for w in ss if not near(w,a) and near(w,b)];out['ray_summary'][k][mode]={'rays':len(ss),'before_near':sum(near(w,a) for w in ss),'after_near':sum(near(w,b) for w in ss),'loss_count':len(loss),'gain_count':len(gain),'loss_evidence':loss}
out['solid_mask_definition']='Exclude B07_PIPE_RACK and ALL B08-prefixed objects, including decorative cloth/cables/grates, so no new decorative cover gets credited.'
for p in sorted((R/'Assets').glob('*.blend'))+sorted((R/'Regions').glob('*.blend')):
 bpy.ops.wm.open_mainfile(filepath=str(p));sc=bpy.context.scene;data={'sha256':sha(p),'objects':len(sc.objects),'dependencies':deps(),'mesh_bounds':{o.name:bounds(o) for o in sc.objects if o.type=='MESH'}}
 if p.parent.name=='Assets':
  mid=p.stem;o=bpy.data.objects.get(mid);expected=np.concatenate([meshpart(x)[0] for x in D['modules'][mid]['parts']]);actual=np.array([v.co[:] for v in o.data.vertices]);data['vertex_count']=len(actual);data['expected_vertex_count']=len(expected);data['maximum_vertex_error_m']=float(abs(actual-expected).max()) if actual.shape==expected.shape else None
 out['assets'][str(p.relative_to(R))]=data
(O/'ray_evidence.json').write_text(json.dumps(wits,indent=2));(O/'scene_audit.json').write_text(json.dumps(out,indent=2));print('B08_INDEPENDENT_SCENE_DONE',json.dumps({k:out[k] for k in ['scene_sha256','baseline_objects','ray_summary']}),flush=True)
