import bpy,json,hashlib,sys,traceback
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:]
ROOT=Path(args[0]).resolve();OUT=Path(args[1]);rows=[]
files=sorted(ROOT.rglob('*.blend'))
for i,p in enumerate(files,1):
 r={'file':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
 try:
  bpy.ops.wm.open_mainfile(filepath=str(p),load_ui=False)
  bpy.context.view_layer.update()
  libraries=[];missing_images=[];outside=[]
  for lib in bpy.data.libraries:
   q=Path(bpy.path.abspath(lib.filepath)).resolve()
   libraries.append({'stored':lib.filepath,'resolved':str(q),'exists':q.is_file(),'inside_delivery':q==ROOT or ROOT in q.parents})
   if q!=ROOT and ROOT not in q.parents:outside.append(str(q))
  for im in bpy.data.images:
   if im.source in {'FILE','TILED'} and not im.packed_file and im.filepath:
    q=Path(bpy.path.abspath(im.filepath,library=im.library))
    if not q.exists():missing_images.append({'image':im.name,'file':str(q)})
  r.update({'opened':True,'objects':len(bpy.data.objects),'mesh_datablocks':len(bpy.data.meshes),'mesh_objects':sum(o.type=='MESH' for o in bpy.data.objects),'collections':len(bpy.data.collections),'scenes':len(bpy.data.scenes),'libraries':libraries,'missing_images':missing_images,'outside_delivery_libraries':outside,'pass':bool(bpy.data.objects or bpy.data.meshes) and not missing_images and not outside and all(x['exists'] for x in libraries)})
 except Exception as e:r.update({'opened':False,'pass':False,'error':repr(e),'traceback':traceback.format_exc()})
 rows.append(r);OUT.parent.mkdir(parents=True,exist_ok=True);OUT.write_text(json.dumps({'pass':all(x['pass'] for x in rows),'checked':len(rows),'expected':len(files),'root':str(ROOT),'blender_version':bpy.app.version_string,'results':rows},ensure_ascii=False,indent=2))
 print('CHECK',i,'/',len(files),r['pass'],r['file'],flush=True)
print('ALL_BLEND_PASS',all(x['pass'] for x in rows),flush=True)
if not all(x['pass'] for x in rows):raise SystemExit(1)
