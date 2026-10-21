"""Read-only final-vs-clean-rebuild geometry signature comparison."""
import bpy,json,pathlib,hashlib,sys,numpy as np
R=pathlib.Path(__file__).resolve().parent.parent
other=pathlib.Path(sys.argv[sys.argv.index('--')+1])
def capture(path):
 bpy.ops.wm.open_mainfile(filepath=str(path));out={}
 for o in bpy.context.scene.objects:
  if o.type not in {'MESH','CURVE','FONT','EMPTY'}:continue
  h=hashlib.sha256();h.update(np.array(o.matrix_world,dtype=np.float32).tobytes());h.update(o.type.encode())
  if o.type=='MESH':
   h.update(np.array([v.co[:] for v in o.data.vertices],dtype=np.float32).tobytes());h.update(str([tuple(p.vertices) for p in o.data.polygons]).encode());h.update(str([p.material_index for p in o.data.polygons]).encode());h.update(str([p.use_smooth for p in o.data.polygons]).encode())
  elif o.type=='FONT':h.update(o.data.body.encode())
  out[o.name]=h.hexdigest()
 return out
a=capture(R/'site_refined.blend');b=capture(other);diff=[n for n in a if a[n]!=b.get(n)];extra=sorted(set(b)-set(a));out={'final_object_signatures':len(a),'rebuild_object_signatures':len(b),'mismatches':diff,'extra':extra,'passed':not diff and not extra,'scope':'All mesh source vertices/faces, transforms, material slots indices, smoothing and text strings. Not byte-identical .blend expectation or UE engine validation.'};(R/'QA/rebuild_verification.json').write_text(json.dumps(out,indent=2));print('REBUILD_VERIFY',json.dumps(out))
