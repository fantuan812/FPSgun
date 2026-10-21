import os,bpy,pathlib,json,sys,itertools,math,hashlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
import numpy as np
R=pathlib.Path('/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement');O=pathlib.Path(os.environ.get('B08_QA_OUTPUT','/workspace/shared/Batch08_Independent_QA'));O.mkdir(parents=True,exist_ok=True);D=json.loads((R/os.environ.get('B08_DESIGN','Config/design.json')).read_text());sys.path.insert(0,str(R/'Scripts'));from analytic_geometry import meshpart
out={'design_sha256':hashlib.sha256((R/os.environ.get('B08_DESIGN','Config/design.json')).read_bytes()).hexdigest(),'modules':{},'cargo_layer_checks':[],'tol_m':.004,'method':'Analytic primitive true triangle overlaps and nearest-surface probes, including old base. Contact tolerance 4mm only for thin surface hardware; graphic overlays not considered structural.'}
for mid,m in D['modules'].items():
 parts=m.get('base_parts',[])+m['parts'];nb=len(m.get('base_parts',[]));vs=[];ts=[];bb=[];probes=[]
 for p in parts:
  v,f=meshpart(p);vs.append(v);ts.append(BVHTree.FromPolygons([Vector(x) for x in v],f));bb.append((v.min(0),v.max(0)));probes.append([Vector(x) for x in v]+[Vector(v[list(face)].mean(0)) for face in f])
 graph={i:set() for i in range(len(parts))};cross=[]
 def distance(i,j):
  if ts[i].overlap(ts[j]):return 0
  # All vertices and face centers, not just a single point; distances are surface distances.
  dist=float('inf')
  for a,b in [(i,j),(j,i)]:
   for x in probes[a]:
    h=ts[b].find_nearest(x)
    if h[3] is not None:dist=min(dist,h[3])
    if dist<.00001:return dist
  return dist
 for i,j in itertools.combinations(range(len(parts)),2):
  gap=np.linalg.norm(np.maximum(0,np.maximum(bb[i][0]-bb[j][1],bb[j][0]-bb[i][1])))
  if gap>.004:continue
  dist=distance(i,j)
  if dist<=.004:graph[i].add(j);graph[j].add(i)
 # Connected sets reveal internally floating groups (rather than accepting an attached label as a parent).
 seen=set();components=[]
 for i in range(len(parts)):
  if i in seen:continue
  stack=[i];cc=[]
  while stack:
   a=stack.pop()
   if a in seen:continue
   seen.add(a);cc.append(a);stack.extend(graph[a]-seen)
  components.append({'indices':cc,'names':[parts[a]['name'] for a in cc],'has_base':any(a<nb for a in cc),'min_z':float(min(bb[a][0][2] for a in cc)),'max_z':float(max(bb[a][1][2] for a in cc))})
 out['modules'][mid]={'part_count':len(parts),'base_part_count':nb,'contact_components':components}
 if mid=='B08_CARGO_DRESSING':
  for i,p in enumerate(parts):
   if i<nb:continue
   if any(s in p['name'] for s in ['cloth side','cloth crown','cloth corner','tension band','webbing ribbon']):
    for j in range(nb):
     if parts[j]['name'] not in ['draped machine cover','continuous tension webbing','metal buckle']:continue
     count=len(ts[i].overlap(ts[j]));
     if count:out['cargo_layer_checks'].append({'new_part_index':i-nb,'new':p['name'],'old_part_index':j,'old':parts[j]['name'],'crossings':count})
  out['new_band_cloth_crossings']=[]
  for i,p in enumerate(parts):
   if i<nb or not any(x in p['name'] for x in ['tension band','webbing ribbon']):continue
   for j,q in enumerate(parts):
    if j<nb or not any(n in q['name'] for n in ['draped cloth','cloth crown','cloth corner']):continue
    count=len(ts[i].overlap(ts[j]))
    if count:out['new_band_cloth_crossings'].append({'band_index':i-nb,'cloth_index':j-nb,'cloth':q['name'],'triangle_pairs':count})
  # Nail placement directly checked against binding/cleat; no nearest unrelated wood.
  out['crate_nails']=[]
  for i,p in enumerate(parts):
   if p['name']=='crate countersunk nail':
    cand=[j for j,q in enumerate(parts[:nb]) if q['name'] in ['crate binding','crate cleat']];vals=[(distance(i,j),j) for j in cand];dd,j=min(vals);out['crate_nails'].append({'position':p['p'],'distance_to_binding_or_cleat_m':dd,'parent':parts[j]['name']})
 print('PARTS_PHASE',mid,len(components),flush=True)
(O/'parts_audit.json').write_text(json.dumps(out,indent=2));print('B08_PARTS_DONE',flush=True)
