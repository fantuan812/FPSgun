"""Actual full PCK directory+MD5 payload/privacy audit, no engine."""
from pathlib import Path
import json,hashlib,sys,re
from parse_pck import parse
R=Path(__file__).parent;T=Path('evidence-workspace/moss-equipment16-integration-candidate');p=Path(sys.argv[1]);output=Path(sys.argv[2]);pack=p.read_bytes();d=parse(p);files=d['files'];errors=[]
markers=[b'/' + b'workspace/',b'/' + b'home/agent/',b'/' + b'tmp/',b'lib' + b'file_',b'file_' + b'000000',b'.codex/' + b'sessions',b'manager' + b':',b'github_' + b'pat_',b'gh' + b'p_']
for m in markers:
 if m in pack:errors.append('wholebytes private marker '+m.decode())
for token in [b'equipment_atlas_v2',b'uid://chrklnkaqwl6m']:
 if token in pack:errors.append('wholebytes old resource marker '+token.decode())
for f in files:
 if any(s in f for s in ['equipment_atlas_v2','chrklnkaqwl6m','equipment_atlas_editable.svg','art_source/icons/','reference_only/','validation_inputs/']):errors.append('forbidden old/source/reference resource '+f)
for f in ['assets/items/icon_manifest.json','assets/items/equipment_atlas_editable.png.import','art_source/alpha_bounds.json']:
 if f not in files:errors.append('missing required '+f)
 elif files[f]['sha256']!=hashlib.sha256((T/f).read_bytes()).hexdigest():errors.append('source bytes differ '+f)
imp=(T/'assets/items/equipment_atlas_editable.png.import').read_text();match=re.search(r'path="res://([^"]+)"',imp);assert match
if match[1] not in files:errors.append('new ctex remap missing')
old=json.loads(Path('evidence-workspace/moss-v39-public-prep/EXPORT_PCK_RAW_REVIEW.json').read_text());forbidden=set(old['reference_original_payload_hashes_excluded']);forbidden.update(v['sha256']for k,v in old['record_identity'].items()if 'equipment_atlas_v2' in k)
for f,v in files.items():
 if v['sha256']in forbidden:errors.append('old/reference payload still present '+f)
expected=json.loads((R/'expected-resources.json').read_text())
for f,h in expected['exact_files'].items():
 if f not in files or files[f]['sha256']!=h:errors.append('runtime exact resource differs '+f)
d.update({'pass':not errors,'errors':errors,'wholebytes_privacy_markers':[m.decode()for m in markers],'old_reference_payload_hashes_forbidden':sorted(forbidden),'exact_runtime_files':len(expected['exact_files']),'scope':'actual PCK full directory/MD5/raw bytes privacy+old resources absent; does not establish runtime rendering'})
output.write_text(json.dumps(d,indent=2)+'\n');print(json.dumps({'pass':not errors,'files':len(files),'errors':errors,'pck_sha256':d['pack_sha256']}));raise SystemExit(0 if not errors else 1)
