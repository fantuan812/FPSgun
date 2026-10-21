"""Package only final Batch04_LargeSpace artifacts. No Batch01 writes. Ordinary, independently extractable ZIP parts."""
from pathlib import Path
import json,hashlib,zlib,zipfile
R=Path(__file__).resolve().parents[1]
OUT=R.parent.parent/'NuclearPlant_Batch04_LargeSpace_Delivery';OUT.mkdir(exist_ok=True)
files=[p for p in sorted(R.rglob('*')) if p.is_file() and p.suffix not in ['.blend1','.log','.pyc'] and '__pycache__' not in p.parts and p.name!='delivery_manifest.json' and not p.name.startswith('debug_') and 'Drafts' not in p.parts]
entries=[{'path':str(p.relative_to(R)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]
(R/'delivery_manifest.json').write_text(json.dumps({'project':'NPP / Sector K-17','batch':4,'files':entries,'excludes':['Blender backup .blend1','Build logs','Python bytecode'],'note':'All final files except this self-referential manifest. ZIP parts contain this manifest once.'},indent=2))
files.append(R/'delivery_manifest.json')
def write_zip(path,items):
 with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in items:z.write(p,arcname='NuclearPlant/Batch04_LargeSpace/'+str(p.relative_to(R)))
 return {'path':str(path),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'file_count':len(items)}
full=write_zip(OUT/'NuclearPlant_Batch04_LargeSpace_Full.zip',files)
# First-fit decreasing packing, with a conservative 7.85 MB ceiling including ZIP directory overhead.
sized=sorted([(p,len(zlib.compress(p.read_bytes(),6))+len(str(p))*2+512) for p in files],key=lambda x:x[1],reverse=True)
groups=[];sizes=[]
for p,n in sized:
 if n>7_850_000:raise RuntimeError('Single artifact too large: '+str(p))
 dest=next((i for i,s in enumerate(sizes) if s+n<=7_850_000),None)
 if dest is None:groups.append([]);sizes.append(0);dest=len(groups)-1
 groups[dest].append(p);sizes[dest]+=n
parts=[write_zip(OUT/f'NuclearPlant_Batch04_LargeSpace_Part_{i+1:02d}_of_{len(groups):02d}.zip',items) for i,items in enumerate(groups)]
expected={ 'NuclearPlant/Batch04_LargeSpace/'+str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files};found={}
for item in parts:
 assert item['bytes']<8_000_000
 with zipfile.ZipFile(item['path']) as z:
  assert z.testzip() is None
  for name in z.namelist():
   assert name not in found
   found[name]=hashlib.sha256(z.read(name)).hexdigest()
assert found==expected
exports=[p for p in files if p.name in ['export.fbx','export.glb','spec.json','README_zh.md','manifest.json','zone_spec.json','placements.json'] or p.name=='final_summary.json']
ue=write_zip(OUT/'NuclearPlant_Batch04_LargeSpace_UE_Exports.zip',exports)
result={'status':'PASS','full':full,'parts':parts,'exports':ue,'verified_files':len(expected),'parts_hashes_match_sources':True,'zip_crc_checked':True,'source_manifest':str(R/'delivery_manifest.json')}
(OUT/'package_verification.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
