import bpy,json,pathlib,hashlib
from mathutils import Vector
P=pathlib.Path('/workspace/shared/NuclearPlant_Cumulative_Final/NuclearPlant/Batch07_Refinement/Assets/B07_SERVICE_CABINET_narrow_045.blend');bpy.ops.wm.open_mainfile(filepath=str(P));out={'file':P.name,'sha256':hashlib.sha256(P.read_bytes()).hexdigest(),'opened':True,'objects':[],'libraries':[x.filepath for x in bpy.data.libraries],'images':[x.filepath for x in bpy.data.images],'fonts':[x.filepath for x in bpy.data.fonts if x.filepath!='<builtin>']}
for o in bpy.context.scene.objects:
 if o.type=='MESH':
  v=[o.matrix_world@Vector(v) for v in o.bound_box];lo=[min(v[i] for v in v) for i in range(3)];hi=[max(v[i] for v in v) for i in range(3)];out['objects'].append({'name':o.name,'scale':list(o.scale),'lo':lo,'hi':hi,'dimensions':[hi[i]-lo[i] for i in range(3)]})
pathlib.Path('/workspace/shared/Batch07_Independent_QA/v04/narrow_asset_audit.json').write_text(json.dumps(out,indent=2));print('NARROW',json.dumps(out),flush=True)
