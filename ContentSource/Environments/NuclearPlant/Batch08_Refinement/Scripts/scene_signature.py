"""Read-only geometry/placement signature, excluding camera/light presentation."""
import bpy,json,pathlib,sys,hashlib
import numpy as np
args=sys.argv[sys.argv.index('--')+1:];paths=args[:-1];dest=pathlib.Path(args[-1]);result=[]
for path in paths:
 bpy.ops.wm.open_mainfile(filepath=path);cache={};objects={}
 for o in bpy.context.scene.objects:
  if o.type in {'CAMERA','LIGHT'}:continue
  d={'type':o.type,'matrix':[round(float(x),7) for row in o.matrix_world for x in row]}
  if o.type=='MESH':
   key=o.data.as_pointer()
   if key not in cache:
    h=hashlib.sha256();h.update(np.array([v.co[:] for v in o.data.vertices],dtype=np.float32).tobytes());h.update(str([tuple(p.vertices) for p in o.data.polygons]).encode());h.update(str([p.material_index for p in o.data.polygons]).encode());h.update(str([m.name if m else None for m in o.data.materials]).encode());cache[key]={'sha256':h.hexdigest(),'vertices':len(o.data.vertices),'polygons':len(o.data.polygons)}
   d.update(cache[key]);d['modifiers']=[{'type':m.type,**({'width':m.width,'segments':m.segments,'limit_method':m.limit_method} if m.type=='BEVEL' else {})} for m in o.modifiers]
  elif o.type=='FONT':d.update({'body':o.data.body,'size':o.data.size,'extrude':o.data.extrude})
  objects[o.name]=d
 payload=json.dumps(objects,sort_keys=True).encode();result.append({'scene':path,'signature_sha256':hashlib.sha256(payload).hexdigest(),'objects':objects,'object_count':len(objects),'mesh_instances':sum(o.type=='MESH' for o in bpy.context.scene.objects),'unique_mesh_data':len(cache)})
if len(result)==2:
 a,b=result;changes=[n for n in sorted(set(a['objects'])|set(b['objects'])) if a['objects'].get(n)!=b['objects'].get(n)];dest.write_text(json.dumps({'equal':not changes,'changed_objects':changes,'original':{k:v for k,v in a.items() if k!='objects'},'rebuilt':{k:v for k,v in b.items() if k!='objects'}},indent=2));assert not changes,changes[:20]
else:dest.write_text(json.dumps(result[0],indent=2))
print('B08_SIGNATURE_OK',dest)
