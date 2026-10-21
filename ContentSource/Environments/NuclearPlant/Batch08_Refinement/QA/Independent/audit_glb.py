"""Read-only structural checks. Does not claim runtime/import/material equivalence."""
import os,pathlib,json,hashlib,struct,datetime
R=pathlib.Path(os.environ.get('B08_ROOT','/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement'))
O=pathlib.Path(os.environ.get('B08_QA_OUTPUT','/workspace/shared/Batch08_Independent_QA/v04'));O.mkdir(parents=True,exist_ok=True)
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
M=json.loads((R/'ALL_MODULES.json').read_text());E=json.loads((R/'Exports/manifest.json').read_text());byname={v['module']:v for v in E};results=[]
for m in M:
 p=R/m['glb'];d=p.read_bytes();errors=[];magic,version,total=struct.unpack_from('<4sII',d);chunks=[];offset=12
 if (magic,version,total)!=(b'glTF',2,len(d)):errors.append('invalid header')
 while offset<len(d):
  n,t=struct.unpack_from('<II',d,offset);offset+=8
  if n%4 or offset+n>len(d):errors.append('invalid aligned chunk bounds')
  chunks.append((t,d[offset:offset+n]));offset+=n
 if not chunks or chunks[0][0]!=0x4e4f534a:errors.append('missing first JSON chunk')
 j=json.loads(chunks[0][1]);bins=[x[1] for x in chunks if x[0]==0x004e4942];external=[]
 for b in j.get('buffers',[]):
  if 'uri' in b:external.append(b['uri'])
  elif len(bins)!=1 or b['byteLength']>len(bins[0]):errors.append('binary buffer missing/too short')
 for im in j.get('images',[]):
  if 'uri' in im and not im['uri'].startswith('data:'):external.append(im['uri'])
 for v in j.get('bufferViews',[]):
  if v['buffer']>=len(j.get('buffers',[])):errors.append('view invalid buffer')
  elif v.get('byteOffset',0)+v['byteLength']>j['buffers'][v['buffer']]['byteLength']:errors.append('view out of range')
 components={5120:1,5121:1,5122:2,5123:2,5125:4,5126:4};sizes={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT2':4,'MAT3':9,'MAT4':16}
 for a in j.get('accessors',[]):
  if 'bufferView' not in a:continue
  v=j['bufferViews'][a['bufferView']];size=components[a['componentType']]*sizes[a['type']];stride=v.get('byteStride',size);end=a.get('byteOffset',0)+max(0,a['count']-1)*stride+size
  if a['count'] and end>v['byteLength']:errors.append('accessor out of view range')
 if external:errors.append('external resource references')
 if not j.get('meshes'):errors.append('no meshes')
 e=byname[m['module_id']];sha=H(p);bs=H(R/m['blend'])
 if sha!=e['sha256']:errors.append('export manifest hash mismatch')
 if bs!=e['source_blend_sha256']:errors.append('source blend manifest hash mismatch')
 results.append({'module':m['module_id'],'path':m['glb'],'sha256':sha,'source_blend':m['blend'],'source_blend_sha256':bs,'bytes':len(d),'meshes':len(j.get('meshes',[])),'nodes':len(j.get('nodes',[])),'materials':len(j.get('materials',[])),'images':len(j.get('images',[])),'external_uris':external,'chunks':[{'type':t,'bytes':len(b)} for t,b in chunks],'errors':errors})
out={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'Independent GLB v2 header/chunk/bufferView/accessor bounds and resource/hash parse, no Blender or game-engine import.','status':'PASS' if len(results)==4 and all(not v['errors'] for v in results) else 'FAIL','modules':results,'script_sha256':H(pathlib.Path(__file__)),'limits':['No GLB runtime/import/collision test.','Base PBR export only; procedural Blender textures are not baked.']};(O/'glb_audit.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
