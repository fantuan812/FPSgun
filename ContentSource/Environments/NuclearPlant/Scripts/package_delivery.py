import pathlib,zipfile,json,hashlib
R=pathlib.Path(__file__).resolve().parents[1];destination=R.parent/'NuclearPlant_Batch01.zip'
allowed_scripts={'build_blockout.py','create_specs.py','build_kit.py','verify_exports.py','verify_interfaces.py','verify_images.py','render_gallery.py','build_assembly.py','package_report.py','package_delivery.py'}
files=[]
for p in R.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(R)
 if p.suffix in ['.blend1','.log','.pyc'] or '__pycache__' in p.parts:continue
 if rel.parts[0]=='Scripts' and p.name not in allowed_scripts:continue
 if rel.parts[0]=='Validation' and p.name.startswith('build_report_') and p.name!='build_report_all.json':continue
 if p.name in ['delivery_manifest.json']:continue
 files.append(p)
manifest={'project':'NPP / Sector K-17','archive':'NuclearPlant_Batch01.zip','files':[{'path':str(p.relative_to(R)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(files)]}
(R/'delivery_manifest.json').write_text(json.dumps(manifest,indent=2));files.append(R/'delivery_manifest.json')
with zipfile.ZipFile(destination,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in sorted(files):z.write(p,'NuclearPlant/'+str(p.relative_to(R)))
with zipfile.ZipFile(destination) as z:
 bad=z.testzip();assert bad is None,bad
print(json.dumps({'archive':str(destination),'bytes':destination.stat().st_size,'files':len(files),'sha256':hashlib.sha256(destination.read_bytes()).hexdigest()},indent=2))
