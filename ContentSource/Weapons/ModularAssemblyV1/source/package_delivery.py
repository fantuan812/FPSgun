"""Explicit repository source-art file list and independently openable <8MiB chat packages."""
from pathlib import Path
import json,hashlib,zipfile
R=Path(__file__).resolve().parents[1];OUT=R/'delivery';OUT.mkdir(exist_ok=True)
paths=[R/'README.zh-CN.md',R/'AetherLab_ThreePlatform_Modular.blend']
for folder in ['inputs','source','config','docs','reference','renders','exports','textures']:
 paths.extend(p for p in (R/folder).rglob('*') if p.is_file() and p.suffix in ['.blend','.py','.json','.md','.png','.glb'] and '__pycache__' not in p.parts and p.name not in ['Repository_File_Manifest.json','Library_Delivery.json'])
paths=sorted(set(paths));items=[{'local_path':str(p.resolve()),'repo_path':'ContentSource/Weapons/ModularAssemblyV1/'+str(p.relative_to(R)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in paths]
(R/'Repository_File_Manifest.json').write_text(json.dumps({'destination_repository':'fantuan812/FPSgun','source_files':items,'total_bytes':sum(x['bytes']for x in items)},indent=2))
# Pack all files except native file and render preview chosen for separate image attachments.
bundles=[];current=[];size=0
for p in paths:
 if p==R/'AetherLab_ThreePlatform_Modular.blend':continue
 n=p.stat().st_size
 if current and size+n>7_700_000:bundles.append(current);current=[];size=0
 current.append(p);size+=n
if current:bundles.append(current)
records=[]
for i,files in enumerate(bundles,1):
 out=OUT/f'FPSgun_Assets_{i:02d}.zip'
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
  for p in files:z.write(p,'ModularAssemblyV1/'+str(p.relative_to(R)))
  z.writestr('PACKAGE_INFO.txt',f'Independent archive {i}; not a multi-volume split. Extract each into same parent folder to preserve ModularAssemblyV1 paths. Individual GLB embeds its images. Source .blend input is exact prior original gun model. No character asset is included.\n')
 with zipfile.ZipFile(out) as z:assert z.testzip() is None
 assert out.stat().st_size<8*1024*1024,(out.name,out.stat().st_size)
 records.append({'file':str(out.resolve()),'name':out.name,'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'members':[str(p.relative_to(R)) for p in files]})
(OUT/'Package_Index.json').write_text(json.dumps(records,indent=2));print(json.dumps({'repo_file_count':len(items),'repo_bytes':sum(x['bytes']for x in items),'packages':[{k:v for k,v in x.items() if k!='members'}for x in records]},indent=2))
